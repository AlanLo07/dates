import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/spotify.dart';
import 'api_config.dart';

class SpotifyService {
  SpotifyService._();

  static final SpotifyService instance = SpotifyService._();

  final String _baseUrl = ApiConfig.baseUrl + ApiConfig.spotifyPath;

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    return Uri.parse('$_baseUrl$path').replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  List<Map<String, dynamic>> _extractItems(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }
    if (body is Map<String, dynamic>) {
      final dynamic direct = body['items'];
      if (direct is List) {
        return direct
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList();
      }
    }
    return const <Map<String, dynamic>>[];
  }

  Future<List<SpotifyTrack>> searchTracks(
    String query, {
    int limit = 10,
    String market = 'CO',
  }) async {
    final response = await http.get(
      _uri('/search', {
        'q': query,
        'type': 'track',
        'limit': limit,
        'market': market,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al buscar canciones en Spotify');
    }

    final body = json.decode(response.body);
    final items = body is Map<String, dynamic>
        ? _extractItems(body['tracks'] is Map<String, dynamic>
            ? body['tracks']
            : body)
        : const <Map<String, dynamic>>[];
    return items.map(SpotifyTrack.fromJson).toList();
  }

  Future<SpotifyRecommendationsResult> getRecommendations({
    required String query,
    int limit = 20,
    String market = 'CO',
    String? mood,
  }) async {
    final queryParameters = <String, dynamic>{
      'q': query,
      'limit': limit,
      'market': market,
    };
    if (mood != null && mood.isNotEmpty) {
      queryParameters['mood'] = mood;
    }

    final response = await http.get(
      _uri('/recommendations', queryParameters),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener recomendaciones de Spotify');
    }

    final body = json.decode(response.body);
    if (body is Map<String, dynamic>) {
      return SpotifyRecommendationsResult.fromJson(body);
    }

    return SpotifyRecommendationsResult(
      tracks: const <SpotifyTrack>[],
      mood: mood,
      fallbackUsed: false,
    );
  }

  Future<List<SpotifyMoodOption>> getMoods() async {
    final response = await http.get(_uri('/moods'));
    if (response.statusCode != 200) {
      return _defaultMoods();
    }

    final body = json.decode(response.body);
    final items = body is List
        ? body
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList()
        : const <Map<String, dynamic>>[];

    if (items.isEmpty) {
      return _defaultMoods();
    }

    return items.map(SpotifyMoodOption.fromJson).toList();
  }

  Future<SpotifyTrack?> getTrack(String id, {String market = 'CO'}) async {
    final response = await http.get(_uri('/tracks/$id', {'market': market}));
    if (response.statusCode != 200) {
      return null;
    }

    final body = json.decode(response.body);
    if (body is Map<String, dynamic>) {
      return SpotifyTrack.fromJson(body);
    }
    return null;
  }

  List<SpotifyMoodOption> _defaultMoods() {
    return const [
      SpotifyMoodOption(
        id: 'romantico',
        label: 'Romántico',
        description: 'Baladas suaves y energía cálida',
        tuners: {
          'target_valence': 0.7,
          'target_energy': 0.45,
        },
      ),
      SpotifyMoodOption(
        id: 'fiesta',
        label: 'Fiesta',
        description: 'Más energía y ritmo para bailar',
        tuners: {
          'target_energy': 0.9,
          'target_danceability': 0.85,
        },
      ),
      SpotifyMoodOption(
        id: 'chill',
        label: 'Chill',
        description: 'Relajado, suave y sin ruido',
        tuners: {
          'target_energy': 0.25,
          'target_acousticness': 0.7,
        },
      ),
      SpotifyMoodOption(
        id: 'focus',
        label: 'Focus',
        description: 'Instrumental o muy ligero',
        tuners: {
          'target_energy': 0.3,
          'target_instrumentalness': 0.8,
        },
      ),
    ];
  }
}