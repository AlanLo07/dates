import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/spotify.dart';
import '../../services/spotify_service.dart';
import '../../services/spotify_web_player/spotify_web_player.dart';

const Color _spotifyGreen = Color(0xFF1DB954);

/// Barra de control de reproduccion de Spotify (requiere cuenta vinculada).
///
/// En Flutter Web usa el Web Playback SDK (crea su propio dispositivo
/// Connect, evitando el error "no active device"). En el resto de
/// plataformas cae al control por REST (play/pause/next/previous), que
/// requiere que el usuario ya tenga un dispositivo Spotify activo.
class SpotifyPlayerBar extends StatefulWidget {
  const SpotifyPlayerBar({super.key});

  @override
  State<SpotifyPlayerBar> createState() => _SpotifyPlayerBarState();
}

class _SpotifyPlayerBarState extends State<SpotifyPlayerBar> {
  final SpotifyService _service = SpotifyService.instance;

  bool _loading = true;
  bool _linked = true;
  bool _busy = false;
  String? _premiumError;

  // --- Modo Web Playback SDK ---
  SpotifyWebPlayer? _webPlayer;
  bool _sdkDeviceReady = false;
  SpotifyWebPlayerState? _sdkState;

  // --- Modo REST (fallback no-web) ---
  SpotifyPlayerState? _restState;

  bool get _usesSdk => SpotifyWebPlayer.isSupported;

  @override
  void initState() {
    super.initState();
    if (_usesSdk) {
      _initSdk();
    } else {
      _loadRestState();
    }
  }

  @override
  void dispose() {
    _webPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initSdk() async {
    setState(() => _loading = true);
    try {
      // Verificamos el vinculo primero para mostrar el CTA correcto
      // (el SDK solo reporta authentication_error una vez conectado).
      await _service.getPlayerState();
      if (!mounted) return;
      setState(() {
        _linked = true;
        _loading = false;
      });
      _connectWebPlayer();
    } on SpotifyNotLinkedException {
      if (!mounted) return;
      setState(() {
        _linked = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _connectWebPlayer() {
    final player = SpotifyWebPlayer(getToken: _service.getPlayerToken);
    _webPlayer = player;

    player.deviceReadyStream.listen((deviceId) async {
      try {
        await _service.transferPlayback(deviceId: deviceId, play: false);
        if (!mounted) return;
        setState(() => _sdkDeviceReady = true);
      } catch (_) {
        // Reintentar quedaria a cargo del usuario reabriendo la pantalla.
      }
    });

    player.stateStream.listen((state) {
      if (!mounted) return;
      setState(() => _sdkState = state);
    });

    player.errorStream.listen((error) {
      if (!mounted) return;
      if (error.startsWith('account_error')) {
        setState(
          () => _premiumError =
              'Se necesita cuenta de Spotify Premium para reproducir aquí',
        );
      } else if (error.startsWith('authentication_error') ||
          error.startsWith('initialization_error')) {
        setState(() => _linked = false);
      }
    });

    player.connect();
  }

  Future<void> _loadRestState() async {
    setState(() => _loading = true);
    try {
      final state = await _service.getPlayerState();
      if (!mounted) return;
      setState(() {
        _restState = state;
        _linked = true;
        _loading = false;
      });
    } on SpotifyNotLinkedException {
      if (!mounted) return;
      setState(() {
        _linked = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _link() async {
    setState(() => _busy = true);
    try {
      final authUrl = await _service.getLoginUrl();
      final uri = Uri.parse(authUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar la vinculación')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _togglePlay() async {
    if (_usesSdk) {
      setState(() => _busy = true);
      try {
        await _webPlayer?.togglePlay();
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    final isPlaying = _restState?.isPlaying ?? false;
    setState(() => _busy = true);
    try {
      if (isPlaying) {
        await _service.pause();
      } else {
        await _service.play();
      }
      await _loadRestState();
    } on SpotifyNotLinkedException {
      if (!mounted) return;
      setState(() => _linked = false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo controlar la reproducción')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip(bool forward) async {
    if (_usesSdk) {
      setState(() => _busy = true);
      try {
        forward
            ? await _webPlayer?.nextTrack()
            : await _webPlayer?.previousTrack();
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    setState(() => _busy = true);
    try {
      if (forward) {
        await _service.next();
      } else {
        await _service.previous();
      }
      await _loadRestState();
    } on SpotifyNotLinkedException {
      if (!mounted) return;
      setState(() => _linked = false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cambiar de canción')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _spotifyGreen,
            ),
          ),
        ),
      );
    }

    if (!_linked) {
      return _MessageBar(
        icon: Icons.link_rounded,
        message: 'Vincula tu cuenta de Spotify para controlar la reproducción',
        actionLabel: 'Vincular',
        onAction: _busy ? null : _link,
      );
    }

    if (_premiumError != null) {
      return _MessageBar(
        icon: Icons.workspace_premium_rounded,
        message: _premiumError!,
      );
    }

    if (_usesSdk) {
      // Esperamos el evento `ready` + transfer antes de habilitar controles.
      if (!_sdkDeviceReady) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _spotifyGreen,
              ),
            ),
          ),
        );
      }

      final track = _sdkState?.track;
      return _PlayerFrame(
        trackName: track?.name ?? '',
        artist: track?.artist ?? '',
        imageUrl: track?.imageUrl ?? '',
        isPlaying: !(_sdkState?.paused ?? true),
        busy: _busy,
        onTogglePlay: _togglePlay,
        onNext: () => _skip(true),
        onPrevious: () => _skip(false),
      );
    }

    final track = _restState?.track;
    return _PlayerFrame(
      trackName: track?.name ?? '',
      artist: track?.artist ?? '',
      imageUrl: track?.imageUrl ?? '',
      isPlaying: _restState?.isPlaying ?? false,
      busy: _busy,
      onTogglePlay: _togglePlay,
      onNext: () => _skip(true),
      onPrevious: () => _skip(false),
    );
  }
}

class _MessageBar extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageBar({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _spotifyGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _spotifyGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _spotifyGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1B1B1B)),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _PlayerFrame extends StatelessWidget {
  final String trackName;
  final String artist;
  final String imageUrl;
  final bool isPlaying;
  final bool busy;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _PlayerFrame({
    required this.trackName,
    required this.artist,
    required this.imageUrl,
    required this.isPlaying,
    required this.busy,
    required this.onTogglePlay,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E0F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: imageUrl.isEmpty
                  ? Container(
                      color: _spotifyGreen.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: _spotifyGreen,
                      ),
                    )
                  : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trackName.isNotEmpty ? trackName : 'Nada en reproducción',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (artist.isNotEmpty)
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: busy ? null : onPrevious,
            icon: const Icon(Icons.skip_previous_rounded),
            color: const Color(0xFF1B1B1B),
          ),
          IconButton(
            onPressed: busy ? null : onTogglePlay,
            icon: Icon(
              isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              size: 34,
            ),
            color: _spotifyGreen,
          ),
          IconButton(
            onPressed: busy ? null : onNext,
            icon: const Icon(Icons.skip_next_rounded),
            color: const Color(0xFF1B1B1B),
          ),
        ],
      ),
    );
  }
}
