import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

export 'package:http/http.dart' show Response;

final AuthenticatedHttpClient _sharedClient = AuthenticatedHttpClient.instance;

Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
    _sharedClient.get(url, headers: headers);

Future<http.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _sharedClient.post(
  url,
  headers: headers,
  body: body,
  encoding: encoding,
);

Future<http.Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _sharedClient.put(
  url,
  headers: headers,
  body: body,
  encoding: encoding,
);

Future<http.Response> patch(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _sharedClient.patch(
  url,
  headers: headers,
  body: body,
  encoding: encoding,
);

Future<http.Response> delete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _sharedClient.delete(
  url,
  headers: headers,
  body: body,
  encoding: encoding,
);

class Client {
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
      _sharedClient.get(url, headers: headers);

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => _sharedClient.post(
    url,
    headers: headers,
    body: body,
    encoding: encoding,
  );

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => _sharedClient.put(
    url,
    headers: headers,
    body: body,
    encoding: encoding,
  );

  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => _sharedClient.patch(
    url,
    headers: headers,
    body: body,
    encoding: encoding,
  );

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => _sharedClient.delete(
    url,
    headers: headers,
    body: body,
    encoding: encoding,
  );

  void close() {}
}

class AuthenticatedHttpClient {
  AuthenticatedHttpClient._();

  static final AuthenticatedHttpClient instance = AuthenticatedHttpClient._();

  final AuthService _authService = AuthService.instance;
  final http.Client _client = http.Client();

  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) => _send('GET', url, headers: headers);

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => _send(
    'POST',
    url,
    headers: headers,
    body: body,
    encoding: encoding,
  );

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => _send(
    'PUT',
    url,
    headers: headers,
    body: body,
    encoding: encoding,
  );

  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => _send(
    'PATCH',
    url,
    headers: headers,
    body: body,
    encoding: encoding,
  );

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => _send(
    'DELETE',
    url,
    headers: headers,
    body: body,
    encoding: encoding,
  );

  Future<http.Response> _send(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final traceCreation = method == 'POST' &&
        (url.path.endsWith('/finances/metas') ||
            url.path.endsWith('/monthly-challenges/current/proposals'));
    final stopwatch = Stopwatch()..start();
    if (traceCreation) {
      debugPrint('⚪️ [AuthenticatedHttpClient] $method ${url.path} autenticando');
    }
    final token = await _authService.getValidAccessToken();
    if (token == null) {
      if (traceCreation) {
        debugPrint('🔴 [AuthenticatedHttpClient] ${url.path} sin sesion; solicitud no enviada');
      }
      throw const AuthException('La sesión ha expirado. Inicia sesión de nuevo.');
    }

    if (traceCreation) {
      debugPrint('🔵 [AuthenticatedHttpClient] $method ${url.path} envio autorizado; '
          'headers=${[...?headers?.keys, 'Authorization'].join(',')}; '
          'OPTIONS, si aparece en web, es preflight del navegador');
    }
    Future<http.Response> send(String accessToken) async {
      try {
        final result = await _request(
          method,
          url,
          headers: _authorizedHeaders(headers, accessToken),
          body: body,
          encoding: encoding,
        );
        if (traceCreation) {
          final requestId = result.headers['x-amzn-requestid'] ??
              result.headers['x-amz-apigw-id'] ?? 'no disponible';
          debugPrint('${result.statusCode >= 400 ? '🔴' : '🟢'} '
              '[AuthenticatedHttpClient] $method ${url.path} '
              'status=${result.statusCode} elapsedMs=${stopwatch.elapsedMilliseconds} '
              'requestId=$requestId');
        }
        return result;
      } catch (error) {
        if (traceCreation) {
          debugPrint('🔴 [AuthenticatedHttpClient] $method ${url.path} '
              'sin respuesta HTTP accesible; tipo=${error.runtimeType}; '
              'en web revisar consola CORS y respuesta OPTIONS '
              '(Allow-Origin, Allow-Methods y Allow-Headers)');
        }
        rethrow;
      }
    }

    var response = await send(token);
    if (response.statusCode != 401) return response;

    debugPrint('🟡 [AuthenticatedHttpClient] token rechazado, renovando sesión');
    final refreshedToken = await _authService.getValidAccessToken(
      forceRefresh: true,
    );
    if (refreshedToken == null) return response;

    response = await send(refreshedToken);
    return response;
  }

  Map<String, String> _authorizedHeaders(
    Map<String, String>? headers,
    String token,
  ) => {
    ...?headers,
    'Authorization': 'Bearer $token',
  };

  Future<http.Response> _request(
    String method,
    Uri url, {
    required Map<String, String> headers,
    Object? body,
    Encoding? encoding,
  }) {
    switch (method) {
      case 'GET':
        return _client.get(url, headers: headers);
      case 'POST':
        return _client.post(
          url,
          headers: headers,
          body: body,
          encoding: encoding,
        );
      case 'PUT':
        return _client.put(
          url,
          headers: headers,
          body: body,
          encoding: encoding,
        );
      case 'PATCH':
        return _client.patch(
          url,
          headers: headers,
          body: body,
          encoding: encoding,
        );
      case 'DELETE':
        return _client.delete(
          url,
          headers: headers,
          body: body,
          encoding: encoding,
        );
      default:
        throw ArgumentError.value(method, 'method', 'Método HTTP no soportado');
    }
  }
}
