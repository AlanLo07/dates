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

class SpotifyMoodOption {
  final String id;
  final String label;
  final String description;
  final Map<String, dynamic> tuners;

  const SpotifyMoodOption({
    required this.id,
    required this.label,
    required this.description,
    required this.tuners,
  });

  factory SpotifyMoodOption.fromJson(Map<String, dynamic> json) {
    return SpotifyMoodOption(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      tuners: (json['tuners'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
  }
}

class SpotifyRecommendationsResult {
  final List<SpotifyTrack> tracks;
  final String? mood;
  final bool fallbackUsed;

  const SpotifyRecommendationsResult({
    required this.tracks,
    required this.mood,
    required this.fallbackUsed,
  });

  factory SpotifyRecommendationsResult.fromJson(Map<String, dynamic> json) {
    final items = _extractTrackItems(json);
    return SpotifyRecommendationsResult(
      tracks: items.map(SpotifyTrack.fromJson).toList(),
      mood: (json['mood'] ?? '').toString().isEmpty
          ? null
          : (json['mood'] ?? '').toString(),
      fallbackUsed: json['fallback_used'] == true,
    );
  }
}

List<Map<String, dynamic>> _extractTrackItems(Map<String, dynamic> json) {
  final dynamic directTracks = json['tracks'];
  if (directTracks is List) {
    return directTracks
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  final dynamic items = json['items'];
  if (items is List) {
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  final dynamic tracks = json['tracks'] is Map<String, dynamic>
      ? (json['tracks'] as Map<String, dynamic>)['items']
      : null;
  if (tracks is List) {
    return tracks
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  return const <Map<String, dynamic>>[];
}