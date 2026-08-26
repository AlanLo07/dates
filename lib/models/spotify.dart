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

