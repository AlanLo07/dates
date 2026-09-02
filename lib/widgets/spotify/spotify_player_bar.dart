import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/spotify.dart';
import '../../services/spotify_service.dart';

const Color _spotifyGreen = Color(0xFF1DB954);

/// Barra de control de reproduccion de Spotify (requiere cuenta vinculada).
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
  SpotifyPlayerState? _state;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    setState(() => _loading = true);
    try {
      final state = await _service.getPlayerState();
      if (!mounted) return;
      setState(() {
        _state = state;
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
    final isPlaying = _state?.isPlaying ?? false;
    setState(() => _busy = true);
    try {
      if (isPlaying) {
        await _service.pause();
      } else {
        await _service.play();
      }
      await _loadState();
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
    setState(() => _busy = true);
    try {
      if (forward) {
        await _service.next();
      } else {
        await _service.previous();
      }
      await _loadState();
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
            const Icon(Icons.link_rounded, color: _spotifyGreen),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Vincula tu cuenta de Spotify para controlar la reproducción',
                style: TextStyle(fontSize: 12, color: Color(0xFF1B1B1B)),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : _link,
              child: const Text('Vincular'),
            ),
          ],
        ),
      );
    }

    final track = _state?.track;
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
              child: track == null || track.imageUrl.isEmpty
                  ? Container(
                      color: _spotifyGreen.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: _spotifyGreen,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: track.imageUrl,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track?.name.isNotEmpty == true
                      ? track!.name
                      : 'Nada en reproducción',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                if (track != null)
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _busy ? null : () => _skip(false),
            icon: const Icon(Icons.skip_previous_rounded),
            color: const Color(0xFF1B1B1B),
          ),
          IconButton(
            onPressed: _busy ? null : _togglePlay,
            icon: Icon(
              (_state?.isPlaying ?? false)
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              size: 34,
            ),
            color: _spotifyGreen,
          ),
          IconButton(
            onPressed: _busy ? null : () => _skip(true),
            icon: const Icon(Icons.skip_next_rounded),
            color: const Color(0xFF1B1B1B),
          ),
        ],
      ),
    );
  }
}
