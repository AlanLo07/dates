import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/spotify.dart';
import '../../services/spotify_service.dart';
import '../../widgets/spotify/spotify_track_tile.dart';

const Color _spotifyGreen = Color(0xFF1DB954);

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  final String? initialName;

  const PlaylistDetailScreen({super.key, required this.playlistId, this.initialName});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final SpotifyService _service = SpotifyService.instance;

  bool _loading = true;
  String? _error;
  SpotifyPlaylist? _playlist;
  List<SpotifyTrack> _tracks = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getPlaylist(widget.playlistId),
        _service.getPlaylistTracks(widget.playlistId),
      ]);
      if (!mounted) return;
      setState(() {
        _playlist = results[0] as SpotifyPlaylist?;
        _tracks = results[1] as List<SpotifyTrack>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la playlist';
        _loading = false;
      });
    }
  }

  Future<void> _openExternal(String url) async {
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialName ?? _playlist?.name ?? 'Playlist'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _spotifyGreen))
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_playlist != null) ...[
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 84,
                          height: 84,
                          child: _playlist!.imageUrl.isEmpty
                              ? Container(
                                  color: _spotifyGreen.withValues(alpha: 0.12),
                                  child: const Icon(Icons.queue_music_rounded, color: _spotifyGreen),
                                )
                              : CachedNetworkImage(imageUrl: _playlist!.imageUrl, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _playlist!.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            if (_playlist!.ownerName.isNotEmpty)
                              Text(
                                'Por ${_playlist!.ownerName} · ${_playlist!.totalTracks} tracks',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            const SizedBox(height: 6),
                            TextButton.icon(
                              onPressed: () => _openExternal(_playlist!.spotifyUrl),
                              icon: const Icon(Icons.open_in_new_rounded, size: 16, color: _spotifyGreen),
                              label: const Text('Abrir en Spotify', style: TextStyle(color: _spotifyGreen)),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                ..._tracks.asMap().entries.map(
                  (entry) => SpotifyTrackTile(
                    track: entry.value,
                    index: entry.key,
                    onTap: () => _openExternal(entry.value.spotifyUrl),
                  ),
                ),
                if (_tracks.isEmpty)
                  Text('Sin tracks disponibles', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
    );
  }
}
