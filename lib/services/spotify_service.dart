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
}