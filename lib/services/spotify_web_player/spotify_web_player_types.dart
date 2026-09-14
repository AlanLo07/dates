/// Tipos compartidos entre la implementación web (JS interop) y el stub
/// usado en plataformas donde el Web Playback SDK no está disponible.
library;

class SpotifyWebPlayerTrack {
  final String id;
  final String name;
  final String artist;
  final String imageUrl;

  const SpotifyWebPlayerTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.imageUrl,
  });
}

class SpotifyWebPlayerState {
  final bool paused;
  final int positionMs;
  final int durationMs;
  final SpotifyWebPlayerTrack? track;

  const SpotifyWebPlayerState({
    required this.paused,
    required this.positionMs,
    required this.durationMs,
    this.track,
  });
}

/// Provee el token crudo de Spotify (con scope `streaming`) que el SDK
/// solicita cada vez que lo necesita (el backend maneja el refresh).
typedef SpotifyTokenProvider = Future<String> Function();
