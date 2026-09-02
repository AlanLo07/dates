class SpotifyTrack {
  final String id;
  final String name;
  final String artist;
  final String albumName;
  final String imageUrl;
  final String spotifyUrl;
  final String previewUrl;
  final int popularity;

  const SpotifyTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.albumName,
    required this.imageUrl,
    required this.spotifyUrl,
    required this.previewUrl,
    required this.popularity,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    final artists = (json['artists'] as List<dynamic>?)
            ?.map((artist) => artist is Map<String, dynamic>
                ? (artist['name'] ?? '').toString()
                : artist.toString())
            .where((name) => name.isNotEmpty)
            .toList() ??
        const <String>[];

    final album = json['album'] is Map<String, dynamic>
        ? json['album'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final images = (album['images'] as List<dynamic>?) ?? const <dynamic>[];
    final imageUrl = images.isNotEmpty && images.first is Map<String, dynamic>
        ? (images.first['url'] ?? '').toString()
        : '';

    final externalUrls = json['external_urls'] is Map<String, dynamic>
        ? json['external_urls'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return SpotifyTrack(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      artist: artists.join(', '),
      albumName: (album['name'] ?? '').toString(),
      imageUrl: imageUrl,
      spotifyUrl: (externalUrls['spotify'] ?? json['url'] ?? '').toString(),
      previewUrl: (json['preview_url'] ?? '').toString(),
      popularity: (json['popularity'] is num)
          ? (json['popularity'] as num).toInt()
          : int.tryParse((json['popularity'] ?? '').toString()) ?? 0,
    );
  }
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}

String _firstImageUrl(dynamic images) {
  if (images is List && images.isNotEmpty && images.first is Map) {
    return ((images.first as Map)['url'] ?? '').toString();
  }
  return '';
}

class SpotifyArtist {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> genres;
  final String spotifyUrl;
  final int popularity;
  final int followers;

  const SpotifyArtist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.genres,
    required this.spotifyUrl,
    required this.popularity,
    required this.followers,
  });

  factory SpotifyArtist.fromJson(Map<String, dynamic> json) {
    final externalUrls = json['external_urls'] is Map<String, dynamic>
        ? json['external_urls'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final followers = json['followers'] is Map<String, dynamic>
        ? json['followers'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return SpotifyArtist(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      imageUrl: _firstImageUrl(json['images']),
      genres: (json['genres'] as List<dynamic>?)
              ?.map((g) => g.toString())
              .toList() ??
          const <String>[],
      spotifyUrl: (externalUrls['spotify'] ?? '').toString(),
      popularity: _asInt(json['popularity']),
      followers: _asInt(followers['total']),
    );
  }
}

class SpotifyAlbum {
  final String id;
  final String name;
  final String artist;
  final String imageUrl;
  final String releaseDate;
  final int totalTracks;
  final String albumType;
  final String spotifyUrl;

  const SpotifyAlbum({
    required this.id,
    required this.name,
    required this.artist,
    required this.imageUrl,
    required this.releaseDate,
    required this.totalTracks,
    required this.albumType,
    required this.spotifyUrl,
  });

  factory SpotifyAlbum.fromJson(Map<String, dynamic> json) {
    final artists = (json['artists'] as List<dynamic>?)
            ?.map((artist) => artist is Map<String, dynamic>
                ? (artist['name'] ?? '').toString()
                : artist.toString())
            .where((name) => name.isNotEmpty)
            .toList() ??
        const <String>[];
    final externalUrls = json['external_urls'] is Map<String, dynamic>
        ? json['external_urls'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return SpotifyAlbum(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      artist: artists.join(', '),
      imageUrl: _firstImageUrl(json['images']),
      releaseDate: (json['release_date'] ?? '').toString(),
      totalTracks: _asInt(json['total_tracks']),
      albumType: (json['album_type'] ?? '').toString(),
      spotifyUrl: (externalUrls['spotify'] ?? '').toString(),
    );
  }
}

class SpotifyPlaylist {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String ownerName;
  final int totalTracks;
  final String spotifyUrl;

  const SpotifyPlaylist({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.ownerName,
    required this.totalTracks,
    required this.spotifyUrl,
  });

  factory SpotifyPlaylist.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] is Map<String, dynamic>
        ? json['owner'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final tracks = json['tracks'] is Map<String, dynamic>
        ? json['tracks'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final externalUrls = json['external_urls'] is Map<String, dynamic>
        ? json['external_urls'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return SpotifyPlaylist(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: _firstImageUrl(json['images']),
      ownerName: (owner['display_name'] ?? '').toString(),
      totalTracks: _asInt(tracks['total']),
      spotifyUrl: (externalUrls['spotify'] ?? '').toString(),
    );
  }
}

class SpotifyDevice {
  final String id;
  final String name;
  final String type;
  final bool isActive;
  final int volumePercent;

  const SpotifyDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
    required this.volumePercent,
  });

  factory SpotifyDevice.fromJson(Map<String, dynamic> json) {
    return SpotifyDevice(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      isActive: json['is_active'] == true,
      volumePercent: _asInt(json['volume_percent']),
    );
  }
}

class SpotifyPlayerState {
  final bool isPlaying;
  final int progressMs;
  final SpotifyTrack? track;
  final SpotifyDevice? device;

  const SpotifyPlayerState({
    required this.isPlaying,
    required this.progressMs,
    this.track,
    this.device,
  });

  factory SpotifyPlayerState.fromJson(Map<String, dynamic> json) {
    final item = json['item'] is Map<String, dynamic>
        ? json['item'] as Map<String, dynamic>
        : null;
    final device = json['device'] is Map<String, dynamic>
        ? json['device'] as Map<String, dynamic>
        : null;

    return SpotifyPlayerState(
      isPlaying: json['is_playing'] == true,
      progressMs: _asInt(json['progress_ms']),
      track: item == null ? null : SpotifyTrack.fromJson(item),
      device: device == null ? null : SpotifyDevice.fromJson(device),
    );
  }
}

