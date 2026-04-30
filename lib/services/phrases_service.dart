// lib/services/hangman_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/phrase.dart';
import 'api_config.dart';

class PhrasesService {
  // TODO: Reemplaza con tu endpoint real cuando lo tengas
  final String _baseUrl = ApiConfig.baseUrl + ApiConfig.phrases;

  /// Obtiene todas las frases (API primero, fallback local)
  Future<List<LovePhrase>> getPhrases() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);

        // Soporta respuesta envuelta { "items": [...] } o array directo
        final List<dynamic> items = body.containsKey('items')
            ? body['items']
            : body;

        return items.map((item) => LovePhrase.fromJson(item)).toList();
      }
    } catch (_) {
      // Sin conexión o error: usamos datos locales
    }

    // Fallback: retorna la lista local
    return [];
  }

  /// Obtiene una frase aleatoria
  Future<LovePhrase> getRandomPhrase() async {
    try {
      final phrases = await getPhrases();
      final random = Random();
      return phrases[random.nextInt(phrases.length)];
    } catch (_) {
      return LovePhrase(
        text: "No hay frases disponibles",
        type: PhraseType.pareja,
        title: "No hay frase",
        emoji: '💌',
      );
    }
  }

  /// Obtiene frases filtradas por tipo
  Future<List<LovePhrase>> getPhrasesByType(PhraseType type) async {
    final all = await getPhrases();
    return all.where((p) => p.type == type).toList();
  }
}
