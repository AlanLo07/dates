import 'dart:async';

import 'spotify_web_player_types.dart';

export 'spotify_web_player_types.dart';

/// Implementación no-web: el Web Playback SDK de Spotify solo corre en el
/// navegador, así que en el resto de plataformas queda deshabilitado.
class SpotifyWebPlayer {
  SpotifyWebPlayer({
    required SpotifyTokenProvider getToken,
    String name = 'APIDates Web Player',
    double initialVolume = 0.5,
  });

  static bool get isSupported => false;

  String? get deviceId => null;

  Stream<SpotifyWebPlayerState?> get stateStream => const Stream.empty();
  Stream<String> get deviceReadyStream => const Stream.empty();
  Stream<String> get errorStream => const Stream.empty();

  Future<void> connect() async {
    throw UnsupportedError(
      'El Web Playback SDK solo está disponible en Flutter Web',
    );
  }

  Future<void> togglePlay() async {}

  Future<void> nextTrack() async {}

  Future<void> previousTrack() async {}

  Future<void> setVolume(double volume) async {}

  void dispose() {}
}
