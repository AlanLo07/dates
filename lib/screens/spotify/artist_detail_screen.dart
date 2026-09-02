import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/spotify.dart';
import '../../services/spotify_service.dart';
import '../../widgets/spotify/spotify_track_tile.dart';
import 'album_detail_screen.dart';

const Color _spotifyGreen = Color(0xFF1DB954);

class ArtistDetailScreen extends StatefulWidget {
  final String artistId;
  final String? initialName;

  const ArtistDetailScreen({super.key, required this.artistId, this.initialName});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  final SpotifyService _service = SpotifyService.instance;

  bool _loading = true;
  String? _error;
  SpotifyArtist? _artist;
  List<SpotifyTrack> _topTracks = const [];
  List<SpotifyAlbum> _albums = const [];

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
        _service.getArtist(widget.artistId),
        _service.getArtistTopTracks(widget.artistId),
        _service.getArtistAlbums(widget.artistId),
      ]);
      if (!mounted) return;
      setState(() {
        _artist = results[0] as SpotifyArtist?;
        _topTracks = results[1] as List<SpotifyTrack>;
        _albums = results[2] as List<SpotifyAlbum>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el artista';
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
        title: Text(widget.initialName ?? _artist?.name ?? 'Artista'),
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
                if (_artist != null) ...[
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 84,
                          height: 84,
                          child: _artist!.imageUrl.isEmpty
                              ? Container(
                                  color: _spotifyGreen.withValues(alpha: 0.12),
                                  child: const Icon(Icons.person_rounded, color: _spotifyGreen),
                                )
                              : CachedNetworkImage(
                                  imageUrl: _artist!.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _artist!.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            if (_artist!.genres.isNotEmpty)
                              Text(
                                _artist!.genres.join(', '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            const SizedBox(height: 6),
                            TextButton.icon(
                              onPressed: () => _openExternal(_artist!.spotifyUrl),
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
                const Text('Top tracks', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                ..._topTracks.asMap().entries.map(
                  (entry) => SpotifyTrackTile(
                    track: entry.value,
                    index: entry.key,
                    onTap: () => _openExternal(entry.value.spotifyUrl),
                  ),
                ),
                if (_topTracks.isEmpty)
                  Text('Sin top tracks disponibles', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 20),
                const Text('Álbumes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                if (_albums.isEmpty)
                  Text('Sin álbumes disponibles', style: TextStyle(color: Colors.grey.shade600))
                else
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _albums.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final album = _albums[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(albumId: album.id, initialName: album.name),
                            ),
                          ),
                          child: SizedBox(
                            width: 130,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 130,
                                    height: 130,
                                    child: album.imageUrl.isEmpty
                                        ? Container(
                                            color: _spotifyGreen.withValues(alpha: 0.12),
                                            child: const Icon(Icons.album_rounded, color: _spotifyGreen),
                                          )
                                        : CachedNetworkImage(imageUrl: album.imageUrl, fit: BoxFit.cover),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  album.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
