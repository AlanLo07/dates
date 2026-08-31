import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class SignupResult {
  final String message;
  final String userSub;
  final bool confirmed;

  const SignupResult({
    required this.message,
    required this.userSub,
    required this.confirmed,
  });
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  factory AuthService() => instance;

  static const _accessTokenKey = 'auth.access_token';
  static const _idTokenKey = 'auth.id_token';
  static const _refreshTokenKey = 'auth.refresh_token';
  static const _expiresAtKey = 'auth.expires_at';
  static const _displayNameKey = 'auth.display_name';
  static const _emailKey = 'auth.email';
  static const _expiryMargin = Duration(seconds: 30);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final http.Client _client = http.Client();
  final ValueNotifier<bool> sessionState = ValueNotifier(false);
  Future<String?>? _refreshInFlight;

  Uri _uri(String path) => Uri.parse(ApiConfig.baseUrl).resolve(
    path.startsWith('/') ? path.substring(1) : path,
  );

  Future<bool> isSessionValid() async {
    try {
      final isValid = await getValidAccessToken() != null;
      sessionState.value = isValid;
      return isValid;
    } catch (_) {
      sessionState.value = false;
      return false;
    }
  }

  Future<bool> signIn({
    String? username,
    String? email,
    required String password,
  }) async {
    final loginEmail = (email ?? username ?? '').trim();
    debugPrint('🔵 [AuthService] signIn: iniciando');
    final response = await _client.post(
      _uri(ApiConfig.loginPath),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': loginEmail, 'password': password}),
    );
    debugPrint(
      '⚪️ [AuthService] signIn: respuesta HTTP ${response.statusCode}',
    );
    if (response.statusCode != 200) {
      debugPrint('🔴 [AuthService] signIn: credenciales rechazadas');
      throw _exceptionFromResponse(response, 'No se pudo iniciar sesión');
    }

    final body = _decodeObject(response);
    await _saveTokens(body, refreshToken: body['refreshToken'] as String?);
    final previousEmail = await _storage.read(key: _emailKey);
    final previousDisplayName = await _storage.read(key: _displayNameKey);
    await _storage.write(key: _emailKey, value: loginEmail);
    if (previousEmail != loginEmail || previousDisplayName?.isEmpty != false) {
      await _storage.write(key: _displayNameKey, value: loginEmail);
    }
    sessionState.value = true;
    debugPrint('🟢 [AuthService] signIn: sesión iniciada');
    return true;
  }

  Future<SignupResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    debugPrint('🔵 [AuthService] signUp: iniciando');
    final response = await _client.post(
      _uri(ApiConfig.signupPath),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'name': name.trim(),
      }),
    );
    debugPrint(
      '⚪️ [AuthService] signUp: respuesta HTTP ${response.statusCode}',
    );
    if (response.statusCode != 201) {
      debugPrint('🔴 [AuthService] signUp: registro rechazado');
      throw _exceptionFromResponse(response, 'No se pudo crear la cuenta');
    }

    final body = _decodeObject(response);
    await _storage.write(key: _emailKey, value: email.trim());
    await _storage.write(key: _displayNameKey, value: name.trim());
    debugPrint('🟢 [AuthService] signUp: registro creado');
    return SignupResult(
      message: body['message'] as String? ?? 'Registro exitoso',
      userSub: body['userSub'] as String? ?? '',
      confirmed: body['confirmed'] as bool? ?? false,
    );
  }

  Future<void> confirmAccount({
    required String email,
    required String code,
  }) async {
    debugPrint('🔵 [AuthService] confirmAccount: iniciando');
    final response = await _client.post(
      _uri(ApiConfig.confirmAccountPath),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'code': code.trim()}),
    );
    debugPrint(
      '⚪️ [AuthService] confirmAccount: respuesta HTTP ${response.statusCode}',
    );
    if (response.statusCode != 200) {
      debugPrint('🔴 [AuthService] confirmAccount: código rechazado');
      throw _exceptionFromResponse(response, 'No se pudo confirmar la cuenta');
    }
    debugPrint('🟢 [AuthService] confirmAccount: cuenta confirmada');
  }

  Future<void> resendConfirmationCode(String email) async {
    debugPrint('🔵 [AuthService] resendCode: iniciando');
    final response = await _client.post(
      _uri(ApiConfig.resendCodePath),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );
    debugPrint(
      '⚪️ [AuthService] resendCode: respuesta HTTP ${response.statusCode}',
    );
    if (response.statusCode != 200) {
      debugPrint('🔴 [AuthService] resendCode: solicitud rechazada');
      throw _exceptionFromResponse(response, 'No se pudo reenviar el código');
    }
    debugPrint('🟢 [AuthService] resendCode: código reenviado');
  }

  Future<String?> getValidAccessToken({bool forceRefresh = false}) async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final expiresAtRaw = await _storage.read(key: _expiresAtKey);
    final expiresAt = DateTime.tryParse(expiresAtRaw ?? '');
    final isCurrent =
        accessToken != null &&
        accessToken.isNotEmpty &&
        expiresAt != null &&
        DateTime.now().add(_expiryMargin).isBefore(expiresAt);

    if (!forceRefresh && isCurrent) return accessToken;
    return refreshAccessToken();
  }

  Future<String?> refreshAccessToken() {
    final activeRefresh = _refreshInFlight;
    if (activeRefresh != null) return activeRefresh;

    final refresh = _performRefresh();
    _refreshInFlight = refresh;
    return refresh.whenComplete(() => _refreshInFlight = null);
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      await clearSession();
      return null;
    }

    debugPrint('🔵 [AuthService] refreshToken: iniciando');
    final response = await _client.post(
      _uri(ApiConfig.refreshTokenPath),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    debugPrint(
      '⚪️ [AuthService] refreshToken: respuesta HTTP ${response.statusCode}',
    );
    if (response.statusCode != 200) {
      debugPrint('🟡 [AuthService] refreshToken: sesión expirada');
      await clearSession();
      return null;
    }

    final body = _decodeObject(response);
    await _saveTokens(body, refreshToken: refreshToken);
    debugPrint('🟢 [AuthService] refreshToken: sesión renovada');
    return body['accessToken'] as String?;
  }

  Future<void> signOut() async {
    debugPrint('🔵 [AuthService] signOut: iniciando');
    final accessToken = await _storage.read(key: _accessTokenKey);
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        final response = await _client.post(
          _uri(ApiConfig.logoutPath),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
        debugPrint(
          '⚪️ [AuthService] signOut: respuesta HTTP ${response.statusCode}',
        );
      }
    } finally {
      await clearSession();
      debugPrint('🟢 [AuthService] signOut: sesión local eliminada');
    }
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _idTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _expiresAtKey),
      _storage.delete(key: _displayNameKey),
      _storage.delete(key: _emailKey),
    ]);
    sessionState.value = false;
  }

  Future<String?> getDisplayName() => _storage.read(key: _displayNameKey);

  Future<String?> getEmail() => _storage.read(key: _emailKey);

  Future<void> _saveTokens(
    Map<String, dynamic> body, {
    required String? refreshToken,
  }) async {
    final accessToken = body['accessToken'] as String?;
    final idToken = body['idToken'] as String?;
    final expiresIn = (body['expiresIn'] as num?)?.toInt();
    if (accessToken == null || accessToken.isEmpty || expiresIn == null) {
      throw const AuthException('La respuesta de autenticación está incompleta');
    }

    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      if (idToken != null) _storage.write(key: _idTokenKey, value: idToken),
      if (refreshToken != null)
        _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _expiresAtKey, value: expiresAt.toIso8601String()),
    ]);
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const AuthException('La respuesta del servidor no es válida');
  }

  AuthException _exceptionFromResponse(
    http.Response response,
    String fallback,
  ) {
    try {
      final body = _decodeObject(response);
      final message = body['message'] ?? body['error'] ?? fallback;
      return AuthException(message.toString(), statusCode: response.statusCode);
    } catch (_) {
      return AuthException(fallback, statusCode: response.statusCode);
    }
  }
}
