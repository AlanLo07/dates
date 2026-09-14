import 'dart:async';
import 'dart:js_util' as js_util;

import 'spotify_web_player_types.dart';

export 'spotify_web_player_types.dart';

bool _scriptInjected = false;
Completer<void>? _sdkReadyCompleter;

Future<void> _ensureSdkLoaded() {
  final existing = _sdkReadyCompleter;
  if (existing != null) return existing.future;

  final completer = Completer<void>();
  _sdkReadyCompleter = completer;

  final existingSpotify = js_util.getProperty(js_util.globalThis, 'Spotify');
  if (existingSpotify != null) {
    completer.complete();
    return completer.future;
  }

  js_util.setProperty(
    js_util.globalThis,
    'onSpotifyWebPlaybackSDKReady',
    js_util.allowInterop(() => completer.complete()),
  );

  if (!_scriptInjected) {
    _scriptInjected = true;
    final document = js_util.getProperty(js_util.globalThis, 'document');
    final script = js_util.callMethod(document, 'createElement', ['script']);
    js_util.setProperty(script, 'src', 'https://sdk.scdn.co/spotify-player.js');
    js_util.setProperty(script, 'async', true);
    final body = js_util.getProperty(document, 'body');
    js_util.callMethod(body, 'appendChild', [script]);
  }

  return completer.future;
}

/// Envoltorio del Web Playback SDK de Spotify vía interop dinámico
/// (`dart:js_util`), usable solo en Flutter Web.
class SpotifyWebPlayer {
  final SpotifyTokenProvider _getToken;
  final String _name;
  final double _initialVolume;

  dynamic _player;
  String? _deviceId;

  final _stateController =
      StreamController<SpotifyWebPlayerState?>.broadcast();
  final _deviceReadyController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  SpotifyWebPlayer({
    required SpotifyTokenProvider getToken,
    String name = 'APIDates Web Player',
    double initialVolume = 0.5,
  }) : _getToken = getToken,
       _name = name,
       _initialVolume = initialVolume;

  static bool get isSupported => true;

  String? get deviceId => _deviceId;

  Stream<SpotifyWebPlayerState?> get stateStream => _stateController.stream;
  Stream<String> get deviceReadyStream => _deviceReadyController.stream;
  Stream<String> get errorStream => _errorController.stream;

  Future<void> connect() async {
    await _ensureSdkLoaded();

    final options = js_util.newObject();
    js_util.setProperty(options, 'name', _name);
    js_util.setProperty(
      options,
      'getOAuthToken',
      js_util.allowInterop((Object callback) {
        _getToken()
            .then((token) {
              js_util.callMethod(callback, 'call', [null, token]);
            })
            .catchError((_) {
              // Si falla, el SDK reporta authentication_error por su cuenta.
            });
      }),
    );
    js_util.setProperty(options, 'volume', _initialVolume);

    final spotifyNamespace = js_util.getProperty(
      js_util.globalThis,
      'Spotify',
    );
    final playerCtor = js_util.getProperty(spotifyNamespace, 'Player');
    _player = js_util.callConstructor(playerCtor, [options]);

    _on('ready', (dynamic data) {
      final id = js_util.getProperty(data, 'device_id') as String?;
      if (id != null) {
        _deviceId = id;
        _deviceReadyController.add(id);
      }
    });

    _on('not_ready', (dynamic _) {
      _deviceId = null;
    });

    _on('player_state_changed', (dynamic state) {
      _stateController.add(_parseState(state));
    });

    for (final event in [
      'initialization_error',
      'authentication_error',
      'account_error',
      'playback_error',
    ]) {
      _on(event, (dynamic data) {
        final message = data == null
            ? event
            : (js_util.getProperty(data, 'message') as String? ?? event);
        _errorController.add('$event: $message');
      });
    }

    js_util.callMethod(_player, 'connect', const []);
  }

  void _on(String event, void Function(dynamic data) callback) {
    js_util.callMethod(_player, 'addListener', [
      event,
      js_util.allowInterop(callback),
    ]);
  }

  SpotifyWebPlayerState? _parseState(dynamic state) {
    if (state == null) return null;
    final paused = js_util.getProperty(state, 'paused') as bool? ?? true;
    final position =
        (js_util.getProperty(state, 'position') as num?)?.toInt() ?? 0;
    final duration =
        (js_util.getProperty(state, 'duration') as num?)?.toInt() ?? 0;
    final trackWindow = js_util.getProperty(state, 'track_window');
    final currentTrack = trackWindow == null
        ? null
        : js_util.getProperty(trackWindow, 'current_track');

    SpotifyWebPlayerTrack? track;
    if (currentTrack != null) {
      final id = js_util.getProperty(currentTrack, 'id') as String? ?? '';
      final name = js_util.getProperty(currentTrack, 'name') as String? ?? '';
      final artistsList = js_util.getProperty(currentTrack, 'artists');
      final artistNames = <String>[];
      if (artistsList != null) {
        final length =
            (js_util.getProperty(artistsList, 'length') as num?)?.toInt() ??
            0;
        for (var i = 0; i < length; i++) {
          final artist = js_util.getProperty(artistsList, '$i');
          final artistName = js_util.getProperty(artist, 'name') as String?;
          if (artistName != null && artistName.isNotEmpty) {
            artistNames.add(artistName);
          }
        }
      }
      final album = js_util.getProperty(currentTrack, 'album');
      var imageUrl = '';
      if (album != null) {
        final images = js_util.getProperty(album, 'images');
        if (images != null) {
          final imagesLength =
              (js_util.getProperty(images, 'length') as num?)?.toInt() ?? 0;
          if (imagesLength > 0) {
            final first = js_util.getProperty(images, '0');
            imageUrl = js_util.getProperty(first, 'url') as String? ?? '';
          }
        }
      }
      track = SpotifyWebPlayerTrack(
        id: id,
        name: name,
        artist: artistNames.join(', '),
        imageUrl: imageUrl,
      );
    }

    return SpotifyWebPlayerState(
      paused: paused,
      positionMs: position,
      durationMs: duration,
      track: track,
    );
  }

  Future<void> togglePlay() => _invoke('togglePlay');

  Future<void> nextTrack() => _invoke('nextTrack');

  Future<void> previousTrack() => _invoke('previousTrack');

  Future<void> setVolume(double volume) => _invoke('setVolume', [volume]);

  Future<void> _invoke(String method, [List<Object?> args = const []]) async {
    if (_player == null) return;
    final result = js_util.callMethod(_player, method, args);
    if (result != null) {
      await js_util.promiseToFuture<void>(result);
    }
  }

  void dispose() {
    if (_player != null) {
      js_util.callMethod(_player, 'disconnect', const []);
    }
    _stateController.close();
    _deviceReadyController.close();
    _errorController.close();
  }
}
