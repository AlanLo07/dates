// lib/services/phrases_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'authenticated_http_client.dart' as http;
import '../models/phrase.dart';
import 'api_config.dart';

class PhrasesService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final PhrasesService _instance = PhrasesService._internal();
  factory PhrasesService() => _instance;
  PhrasesService._internal();

  final String _baseUrl = ApiConfig.baseUrl + ApiConfig.phrases;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // ── Cache en memoria ───────────────────────────────────────────────────────
  List<LovePhrase>? _cache;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(minutes: 10);

  bool get _isCacheValid =>
      _cache != null &&
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheTtl;

  void invalidateCache() {
    _cache = null;
    _cacheTimestamp = null;
    debugPrint('⚪️ [PhrasesService] invalidateCache: cache limpiado');
  }

  // ── Obtener frases ─────────────────────────────────────────────────────────
  Future<List<LovePhrase>> getPhrases({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) return _cache!;

    try {
      debugPrint('⚪️ [PhrasesService] getPhrases: GET iniciado');
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 5));

      debugPrint(
        '⚪️ [PhrasesService] getPhrases: respuesta HTTP ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);

        // ── FIX: maneja { "items": [...] }, { "phrases": [...] } y array directo
        List<dynamic> items;
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map) {
          items = (decoded['items'] ?? decoded['phrases'] ?? []) as List;
        } else {
          items = [];
        }

        if (items.isNotEmpty) {
          _cache = items
              .map((e) => LovePhrase.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _cacheTimestamp = DateTime.now();
          debugPrint(
            '🟢 [PhrasesService] getPhrases: ${_cache!.length} frases '
            '(${_cache!.where((p) => p.completado).length} completadas)',
          );
          return _cache!;
        }
      }
    } catch (error) {
      debugPrint('🔴 [PhrasesService] getPhrases: error $error');
      // Sin conexión → fallback local (sin romper la UI)
    }

    return [];
  }

  // ── Crear frase ────────────────────────────────────────────────────────────
  Future<LovePhrase?> createPhrase(LovePhrase phrase) async {
    try {
      debugPrint('🔵 [PhrasesService] createPhrase: POST iniciado');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: json.encode(phrase.toJson()),
      );

      debugPrint(
        '⚪️ [PhrasesService] createPhrase: respuesta HTTP ${response.statusCode}',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        invalidateCache();
        debugPrint('🟢 [PhrasesService] createPhrase: completado');
        return _extractPhrase(response.body) ?? phrase;
      }
    } catch (error) {
      debugPrint('🔴 [PhrasesService] createPhrase: error $error');
    }
    return null;
  }

  // ── Actualizar frase ───────────────────────────────────────────────────────
  Future<LovePhrase?> updatePhrase(LovePhrase phrase) async {
    if (phrase.id.isEmpty) {
      debugPrint('🟡 [PhrasesService] updatePhrase: frase sin id, se omite');
      return null;
    }

    try {
      debugPrint(
        '🔵 [PhrasesService] updatePhrase: PUT iniciado (${phrase.id})',
      );
      final response = await http.put(
        Uri.parse('$_baseUrl/${phrase.id}'),
        headers: _headers,
        body: json.encode(phrase.toJson()),
      );

      debugPrint(
        '⚪️ [PhrasesService] updatePhrase: respuesta HTTP ${response.statusCode}',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final updated = _extractPhrase(response.body) ?? phrase;
        _replaceInCache(updated);
        debugPrint('🟢 [PhrasesService] updatePhrase: completado');
        return updated;
      }
    } catch (error) {
      debugPrint('🔴 [PhrasesService] updatePhrase: error $error');
    }
    return null;
  }

  // ── Marcar como completada ─────────────────────────────────────────────────
  Future<LovePhrase?> markAsCompleted(LovePhrase phrase) async {
    if (phrase.completado) return phrase;
    debugPrint('🔵 [PhrasesService] markAsCompleted: frase ${phrase.id}');
    return updatePhrase(phrase.copyWith(completado: true));
  }

  LovePhrase? _extractPhrase(String body) {
    if (body.isEmpty) return null;
    final dynamic decoded = json.decode(body);
    if (decoded is Map) {
      final dynamic raw = decoded['item'] ?? decoded['phrase'] ?? decoded;
      if (raw is Map && raw['text'] != null) {
        return LovePhrase.fromJson(Map<String, dynamic>.from(raw));
      }
    }
    return null;
  }

  void _replaceInCache(LovePhrase phrase) {
    final cache = _cache;
    if (cache == null || phrase.id.isEmpty) return;
    final index = cache.indexWhere((p) => p.id == phrase.id);
    if (index >= 0) cache[index] = phrase;
  }

  // ── Frase aleatoria ────────────────────────────────────────────────────────
  Future<LovePhrase> getRandomPhrase() async {
    try {
      final phrases = await getPhrases();
      if (phrases.isEmpty) return _fallback();
      return phrases[Random().nextInt(phrases.length)];
    } catch (_) {
      return _fallback();
    }
  }

  // ── Por tipo ───────────────────────────────────────────────────────────────
  Future<List<LovePhrase>> getPhrasesByType(PhraseType type) async {
    final all = await getPhrases();
    return all.where((p) => p.type == type).toList();
  }

  Future<List<LovePhrase>> getCompletedPhrasesByType(PhraseType type) async {
    final byType = await getPhrasesByType(type);
    return byType.where((p) => p.completado).toList();
  }

  Future<List<LovePhrase>> getPendingPhrasesByType(PhraseType type) async {
    final byType = await getPhrasesByType(type);
    return byType.where((p) => !p.completado).toList();
  }

  /// Frase aleatoria sin completar del tipo indicado. `null` si ya no quedan.
  Future<LovePhrase?> getRandomPendingPhrase(PhraseType type) async {
    final pending = await getPendingPhrasesByType(type);
    if (pending.isEmpty) {
      debugPrint('🟡 [PhrasesService] getRandomPendingPhrase: sin pendientes');
      return null;
    }
    return pending[Random().nextInt(pending.length)];
  }

  // ── Fallback cuando no hay datos ───────────────────────────────────────────
  LovePhrase _fallback() => const LovePhrase(
    text: 'No hay frases disponibles',
    type: PhraseType.pareja,
    title: 'Sin frase',
    emoji: '💌',
  );
}
