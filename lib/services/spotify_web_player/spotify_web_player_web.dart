import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'spotify_web_player_types.dart';

export 'spotify_web_player_types.dart';

bool _scriptInjected = false;
Completer<void>? _sdkReadyCompleter;

T? _property<T extends JSAny?>(JSAny? object, String property) =>
    object == null ? null : (object as JSObject).getProperty<T>(property.toJS);

String? _stringProperty(JSAny? object, String property) =>
    _property<JSString?>(object, property)?.toDart;

Future<void> _ensureSdkLoaded() {
  final existing = _sdkReadyCompleter;
  if (existing != null) return existing.future;

  final completer = Completer<void>();
  _sdkReadyCompleter = completer;

  final existingSpotify = globalContext.getProperty<JSAny?>('Spotify'.toJS);
  if (existingSpotify != null) {
    completer.complete();
    return completer.future;
  }

  globalContext.setProperty(
    'onSpotifyWebPlaybackSDKReady'.toJS,
    (() => completer.complete()).toJS,
  );

  if (!_scriptInjected) {
    _scriptInjected = true;
    final document = globalContext.getProperty<JSObject>('document'.toJS);
    final script = document.callMethod<JSObject>(
      'createElement'.toJS,
      ['script'.toJS].toJS,
    );
    script.setProperty(
      'src'.toJS,
      'https://sdk.scdn.co/spotify-player.js'.toJS,
    );
    script.setProperty('async'.toJS, true.toJS);
    final body = document.getProperty<JSObject>('body'.toJS);
    body.callMethod<JSAny?>('appendChild'.toJS, [script].toJS);
  }

  return completer.future;
}

/// Envoltorio del Web Playback SDK de Spotify vía interop dinámico
/// (`dart:js_interop`), usable solo en Flutter Web.
class SpotifyWebPlayer {
  final SpotifyTokenProvider _getToken;
  final String _name;
  final double _initialVolume;

  JSObject? _player;
  String? _deviceId;

  final _stateController = StreamController<SpotifyWebPlayerState?>.broadcast();
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

    final options = globalContext
        .getProperty<JSFunction>('Object'.toJS)
        .callMethod<JSObject>('create'.toJS, [null].toJS);
    options.setProperty('name'.toJS, _name.toJS);
    options.setProperty(
      'getOAuthToken'.toJS,
      ((JSAny? callback) {
        _getToken()
            .then((token) {
              (callback as JSObject?)?.callMethod<JSAny?>(
                'call'.toJS,
                [null, token.toJS].toJS,
              );
            })
            .catchError((_) {
              // Si falla, el SDK reporta authentication_error por su cuenta.
            });
      }).toJS,
    );
    options.setProperty('volume'.toJS, _initialVolume.toJS);

    final spotifyNamespace = globalContext.getProperty<JSObject>(
      'Spotify'.toJS,
    );
    final playerCtor = spotifyNamespace.getProperty<JSFunction?>('Player'.toJS);
    if (playerCtor == null) {
      throw StateError('No se pudo cargar Spotify.Player');
    }
    _player = playerCtor.callAsConstructor<JSObject>([options].toJS);

    _on('ready', (JSAny? data) {
      final id = _stringProperty(data, 'device_id');
      if (id != null) {
        _deviceId = id;
        _deviceReadyController.add(id);
      }
    });

    _on('not_ready', (JSAny? _) {
      _deviceId = null;
    });

    _on('player_state_changed', (JSAny? state) {
      _stateController.add(_parseState(state));
    });

    for (final event in [
      'initialization_error',
      'authentication_error',
      'account_error',
      'playback_error',
    ]) {
      _on(event, (JSAny? data) {
        final message = data == null
            ? event
            : (_stringProperty(data, 'message') ?? event);
        _errorController.add('$event: $message');
      });
    }

    _player!.callMethod<JSAny?>('connect'.toJS, <JSAny?>[].toJS);
  }

  void _on(String event, void Function(JSAny? data) callback) {
    _player!.callMethod<JSAny?>(
      'addListener'.toJS,
      [event.toJS, callback.toJS].toJS,
    );
  }

  SpotifyWebPlayerState? _parseState(JSAny? state) {
    if (state == null) return null;
    final paused = _property<JSBoolean?>(state, 'paused')?.toDart ?? true;
    final position =
        _property<JSNumber?>(state, 'position')?.toDartDouble.toInt() ?? 0;
    final duration =
        _property<JSNumber?>(state, 'duration')?.toDartDouble.toInt() ?? 0;
    final trackWindow = _property<JSAny?>(state, 'track_window');
    final currentTrack = trackWindow == null
        ? null
        : _property<JSAny?>(trackWindow, 'current_track');

    SpotifyWebPlayerTrack? track;
    if (currentTrack != null) {
      final id = _stringProperty(currentTrack, 'id') ?? '';
      final name = _stringProperty(currentTrack, 'name') ?? '';
      final artistsList = _property<JSAny?>(currentTrack, 'artists');
      final artistNames = <String>[];
      if (artistsList != null) {
        final length =
            _property<JSNumber?>(artistsList, 'length')?.toDartDouble.toInt() ??
            0;
        for (var i = 0; i < length; i++) {
          final artist = _property<JSAny?>(artistsList, '$i');
          final artistName = _stringProperty(artist, 'name');
          if (artistName != null && artistName.isNotEmpty) {
            artistNames.add(artistName);
          }
        }
      }
      final album = _property<JSAny?>(currentTrack, 'album');
      var imageUrl = '';
      if (album != null) {
        final images = _property<JSAny?>(album, 'images');
        if (images != null) {
          final imagesLength =
              _property<JSNumber?>(images, 'length')?.toDartDouble.toInt() ?? 0;
          if (imagesLength > 0) {
            final first = _property<JSAny?>(images, '0');
            imageUrl = _stringProperty(first, 'url') ?? '';
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

  Future<void> setVolume(double volume) => _invoke('setVolume', [volume.toJS]);

  Future<void> _invoke(String method, [List<JSAny?> args = const []]) async {
    if (_player == null) return;
    final result = _player!.callMethod<JSAny?>(method.toJS, args.toJS);
    if (result != null) {
      await (result as JSPromise<JSAny?>).toDart;
    }
  }

  void dispose() {
    if (_player != null) {
      _player!.callMethod<JSAny?>('disconnect'.toJS, <JSAny?>[].toJS);
    }
    _stateController.close();
    _deviceReadyController.close();
    _errorController.close();
  }
}
