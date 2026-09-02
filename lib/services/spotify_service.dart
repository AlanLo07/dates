import 'dart:convert';

import 'authenticated_http_client.dart' as http;

import '../models/spotify.dart';
import 'api_config.dart';

/// Se lanza cuando el usuario aun no vinculo su cuenta de Spotify
/// (endpoints /spotify/player/* responden 400).
class SpotifyNotLinkedException implements Exception {
  final String message;
  const SpotifyNotLinkedException([
    this.message = 'Usuario no ha vinculado su cuenta de Spotify',
  ]);

  @override
  String toString() => message;
}

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

  Future<List<SpotifyArtist>> searchArtists(
    String query, {
    int limit = 10,
    String market = 'CO',
  }) async {
    final response = await http.get(
      _uri('/search', {
        'q': query,
        'type': 'artist',
        'limit': limit,
        'market': market,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al buscar artistas en Spotify');
    }
    final body = json.decode(response.body);
    final items = body is Map<String, dynamic>
        ? _extractItems(
            body['artists'] is Map<String, dynamic> ? body['artists'] : body,
          )
        : const <Map<String, dynamic>>[];
    return items.map(SpotifyArtist.fromJson).toList();
  }

  Future<List<SpotifyAlbum>> searchAlbums(
    String query, {
    int limit = 10,
    String market = 'CO',
  }) async {
    final response = await http.get(
      _uri('/search', {
        'q': query,
        'type': 'album',
        'limit': limit,
        'market': market,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al buscar álbumes en Spotify');
    }
    final body = json.decode(response.body);
    final items = body is Map<String, dynamic>
        ? _extractItems(
            body['albums'] is Map<String, dynamic> ? body['albums'] : body,
          )
        : const <Map<String, dynamic>>[];
    return items.map(SpotifyAlbum.fromJson).toList();
  }

  Future<List<SpotifyPlaylist>> searchPlaylists(
    String query, {
    int limit = 10,
    String market = 'CO',
  }) async {
    final response = await http.get(
      _uri('/search', {
        'q': query,
        'type': 'playlist',
        'limit': limit,
        'market': market,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al buscar playlists en Spotify');
    }
    final body = json.decode(response.body);
    final items = body is Map<String, dynamic>
        ? _extractItems(
            body['playlists'] is Map<String, dynamic>
                ? body['playlists']
                : body,
          )
        : const <Map<String, dynamic>>[];
    return items.map(SpotifyPlaylist.fromJson).toList();
  }

  Future<SpotifyArtist?> getArtist(String id) async {
    final response = await http.get(_uri('/artists/$id'));
    if (response.statusCode != 200) return null;
    final body = json.decode(response.body);
    return body is Map<String, dynamic> ? SpotifyArtist.fromJson(body) : null;
  }

  Future<List<SpotifyTrack>> getArtistTopTracks(
    String id, {
    String market = 'CO',
    int limit = 10,
  }) async {
    final response = await http.get(
      _uri('/artists/$id/top-tracks', {'market': market, 'limit': limit}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al obtener top tracks del artista');
    }
    final body = json.decode(response.body);
    final items = _extractItems(body);
    return items.map(SpotifyTrack.fromJson).toList();
  }

  Future<List<SpotifyAlbum>> getArtistAlbums(
    String id, {
    String market = 'CO',
    int limit = 20,
    int offset = 0,
    String? includeGroups,
  }) async {
    final query = {
      'market': market,
      'limit': limit,
      'offset': offset,
      if (includeGroups != null) 'include_groups': includeGroups,
    };
    final response = await http.get(_uri('/artists/$id/albums', query));
    if (response.statusCode != 200) {
      throw Exception('Error al obtener álbumes del artista');
    }
    final body = json.decode(response.body);
    final items = _extractItems(body);
    return items.map(SpotifyAlbum.fromJson).toList();
  }

  Future<SpotifyAlbum?> getAlbum(String id, {String market = 'CO'}) async {
    final response = await http.get(_uri('/albums/$id', {'market': market}));
    if (response.statusCode != 200) return null;
    final body = json.decode(response.body);
    return body is Map<String, dynamic> ? SpotifyAlbum.fromJson(body) : null;
  }

  Future<List<SpotifyTrack>> getAlbumTracks(
    String id, {
    String market = 'CO',
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await http.get(
      _uri('/albums/$id/tracks', {
        'market': market,
        'limit': limit,
        'offset': offset,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al obtener tracks del álbum');
    }
    final body = json.decode(response.body);
    final items = _extractItems(body);
    return items.map(SpotifyTrack.fromJson).toList();
  }

  Future<SpotifyPlaylist?> getPlaylist(
    String id, {
    String market = 'CO',
  }) async {
    final response = await http.get(
      _uri('/playlists/$id', {'market': market}),
    );
    if (response.statusCode != 200) return null;
    final body = json.decode(response.body);
    return body is Map<String, dynamic>
        ? SpotifyPlaylist.fromJson(body)
        : null;
  }

  Future<List<SpotifyTrack>> getPlaylistTracks(
    String id, {
    String market = 'CO',
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await http.get(
      _uri('/playlists/$id/tracks', {
        'market': market,
        'limit': limit,
        'offset': offset,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al obtener tracks de la playlist');
    }
    final body = json.decode(response.body);
    // Cada item de tracks de playlist viene envuelto en { track: {...} }.
    final rawItems = _extractItems(body);
    return rawItems
        .map((item) {
          final track = item['track'];
          return track is Map<String, dynamic> ? track : item;
        })
        .map(SpotifyTrack.fromJson)
        .toList();
  }

  /// Pide la URL de autorizacion de Spotify (requiere JWT de la app).
  Future<String> getLoginUrl() async {
    final response = await http.get(_uri('/login'));
    if (response.statusCode != 200) {
      throw Exception('No se pudo iniciar la vinculación con Spotify');
    }
    final body = json.decode(response.body);
    if (body is Map<String, dynamic> && body['authUrl'] is String) {
      return body['authUrl'] as String;
    }
    throw Exception('Respuesta inválida al vincular Spotify');
  }

  void _throwIfNotLinked(http.Response response) {
    if (response.statusCode == 400) {
      throw const SpotifyNotLinkedException();
    }
  }

  Future<SpotifyPlayerState?> getPlayerState({String market = 'CO'}) async {
    final response = await http.get(_uri('/player', {'market': market}));
    _throwIfNotLinked(response);
    if (response.statusCode == 204 || response.body.isEmpty) return null;
    if (response.statusCode != 200) {
      throw Exception('Error al obtener el estado del reproductor');
    }
    final body = json.decode(response.body);
    return body is Map<String, dynamic>
        ? SpotifyPlayerState.fromJson(body)
        : null;
  }

  Future<SpotifyTrack?> getCurrentlyPlaying({String market = 'CO'}) async {
    final response = await http.get(
      _uri('/player/currently-playing', {'market': market}),
    );
    _throwIfNotLinked(response);
    if (response.statusCode == 204 || response.body.isEmpty) return null;
    if (response.statusCode != 200) {
      throw Exception('Error al obtener la canción actual');
    }
    final body = json.decode(response.body);
    if (body is Map<String, dynamic> && body['item'] is Map<String, dynamic>) {
      return SpotifyTrack.fromJson(body['item'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<SpotifyDevice>> getDevices() async {
    final response = await http.get(_uri('/player/devices'));
    _throwIfNotLinked(response);
    if (response.statusCode != 200) {
      throw Exception('Error al obtener los dispositivos');
    }
    final body = json.decode(response.body);
    final items = _extractItems(body);
    return items.map(SpotifyDevice.fromJson).toList();
  }

  Future<void> play({String? deviceId, String? contextUri, List<String>? uris}) async {
    final response = await http.put(
      _uri('/player/play', {if (deviceId != null) 'device_id': deviceId}),
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({
        if (contextUri != null) 'context_uri': contextUri,
        if (uris != null) 'uris': uris,
      }),
    );
    _throwIfNotLinked(response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al reproducir en Spotify');
    }
  }

  Future<void> pause({String? deviceId}) async {
    final response = await http.put(
      _uri('/player/pause', {if (deviceId != null) 'device_id': deviceId}),
    );
    _throwIfNotLinked(response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al pausar en Spotify');
    }
  }

  Future<void> setVolume(int volumePercent, {String? deviceId}) async {
    final response = await http.put(
      _uri('/player/volume', {
        'volume_percent': volumePercent,
        if (deviceId != null) 'device_id': deviceId,
      }),
    );
    _throwIfNotLinked(response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al ajustar el volumen en Spotify');
    }
  }

  Future<void> next({String? deviceId}) async {
    final response = await http.post(
      _uri('/player/next', {if (deviceId != null) 'device_id': deviceId}),
    );
    _throwIfNotLinked(response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al saltar de canción en Spotify');
    }
  }

  Future<void> previous({String? deviceId}) async {
    final response = await http.post(
      _uri('/player/previous', {if (deviceId != null) 'device_id': deviceId}),
    );
    _throwIfNotLinked(response);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al ir a la canción anterior en Spotify');
    }
  }
}