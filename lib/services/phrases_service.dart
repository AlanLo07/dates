// lib/services/phrases_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/phrase.dart';
import 'api_config.dart';

class PhrasesService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final PhrasesService _instance = PhrasesService._internal();
  factory PhrasesService() => _instance;
  PhrasesService._internal();

  final String _baseUrl = ApiConfig.baseUrl + ApiConfig.phrases;

  // ── Cache en memoria ───────────────────────────────────────────────────────
  List<LovePhrase>? _cache;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(minutes: 10);

  bool get _isCacheValid =>
      _cache != null &&
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheTtl;

  // ── Obtener frases ─────────────────────────────────────────────────────────
  Future<List<LovePhrase>> getPhrases({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) return _cache!;

    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 5));

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
          _cache = items.map((e) => LovePhrase.fromJson(e)).toList();
          _cacheTimestamp = DateTime.now();
          return _cache!;
        }
      }
    } catch (_) {
      // Sin conexión → fallback local (sin romper la UI)
    }

    return [];
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

  // ── Fallback cuando no hay datos ───────────────────────────────────────────
  LovePhrase _fallback() => const LovePhrase(
    text: 'No hay frases disponibles',
    type: PhraseType.pareja,
    title: 'Sin frase',
    emoji: '💌',
  );
}
