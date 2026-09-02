import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/spotify.dart';
import '../../services/spotify_service.dart';
import '../../widgets/spotify/spotify_player_bar.dart';
import '../../widgets/spotify/spotify_track_tile.dart';
import 'album_detail_screen.dart';
import 'artist_detail_screen.dart';
import 'playlist_detail_screen.dart';

const Color _spotifyGreen = Color(0xFF1DB954);

/// Pantalla principal para buscar y explorar catálogo de Spotify
/// (tracks, artistas, álbumes y playlists) con control de reproducción.
class SpotifyExplorerScreen extends StatefulWidget {
  const SpotifyExplorerScreen({super.key});

  @override
  State<SpotifyExplorerScreen> createState() => _SpotifyExplorerScreenState();
}

class _SpotifyExplorerScreenState extends State<SpotifyExplorerScreen>
    with SingleTickerProviderStateMixin {
  final SpotifyService _service = SpotifyService.instance;
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;

  bool _loading = false;
  String _query = '';

  List<SpotifyTrack> _tracks = const [];
  List<SpotifyArtist> _artists = const [];
  List<SpotifyAlbum> _albums = const [];
  List<SpotifyPlaylist> _playlists = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    _query = trimmed;
    if (trimmed.isEmpty) {
      setState(() {
        _tracks = const [];
        _artists = const [];
        _albums = const [];
        _playlists = const [];
      });
      return;
    }

    setState(() => _loading = true);
    try {
      switch (_tabController.index) {
        case 0:
          final tracks = await _service.searchTracks(trimmed);
          if (mounted && _query == trimmed) setState(() => _tracks = tracks);
          break;
        case 1:
          final artists = await _service.searchArtists(trimmed);
          if (mounted && _query == trimmed) setState(() => _artists = artists);
          break;
        case 2:
          final albums = await _service.searchAlbums(trimmed);
          if (mounted && _query == trimmed) setState(() => _albums = albums);
          break;
        case 3:
          final playlists = await _service.searchPlaylists(trimmed);
          if (mounted && _query == trimmed) setState(() => _playlists = playlists);
          break;
      }
    } catch (_) {
      // Silencioso: se muestra el estado vacío correspondiente.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openExternal(String url) async {
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text('Spotify'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _spotifyGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _spotifyGreen,
          onTap: (_) => _search(_searchController.text),
          tabs: const [
            Tab(text: 'Canciones'),
            Tab(text: 'Artistas'),
            Tab(text: 'Álbumes'),
            Tab(text: 'Playlists'),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const SpotifyPlayerBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: _search,
              onChanged: (value) {
                if (value.trim().isEmpty) _search(value);
              },
              decoration: InputDecoration(
                hintText: 'Buscar en Spotify...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _spotifyGreen))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTracksTab(),
                      _buildArtistsTab(),
                      _buildAlbumsTab(),
                      _buildPlaylistsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message) => Center(
        child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
      );

  Widget _buildTracksTab() {
    if (_tracks.isEmpty) return _buildEmpty('Busca canciones en Spotify');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return SpotifyTrackTile(
          track: track,
          onTap: () => _openExternal(track.spotifyUrl),
        );
      },
    );
  }

  Widget _buildArtistsTab() {
    if (_artists.isEmpty) return _buildEmpty('Busca artistas en Spotify');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        final artist = _artists[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 44,
              height: 44,
              child: artist.imageUrl.isEmpty
                  ? Container(
                      color: _spotifyGreen.withValues(alpha: 0.12),
                      child: const Icon(Icons.person_rounded, color: _spotifyGreen),
                    )
                  : CachedNetworkImage(imageUrl: artist.imageUrl, fit: BoxFit.cover),
            ),
          ),
          title: Text(artist.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: artist.genres.isNotEmpty
              ? Text(artist.genres.take(2).join(', '), maxLines: 1, overflow: TextOverflow.ellipsis)
              : null,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ArtistDetailScreen(artistId: artist.id, initialName: artist.name),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsTab() {
    if (_albums.isEmpty) return _buildEmpty('Busca álbumes en Spotify');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: album.imageUrl.isEmpty
                  ? Container(
                      color: _spotifyGreen.withValues(alpha: 0.12),
                      child: const Icon(Icons.album_rounded, color: _spotifyGreen),
                    )
                  : CachedNetworkImage(imageUrl: album.imageUrl, fit: BoxFit.cover),
            ),
          ),
          title: Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(album.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AlbumDetailScreen(albumId: album.id, initialName: album.name),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsTab() {
    if (_playlists.isEmpty) return _buildEmpty('Busca playlists en Spotify');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: playlist.imageUrl.isEmpty
                  ? Container(
                      color: _spotifyGreen.withValues(alpha: 0.12),
                      child: const Icon(Icons.queue_music_rounded, color: _spotifyGreen),
                    )
                  : CachedNetworkImage(imageUrl: playlist.imageUrl, fit: BoxFit.cover),
            ),
          ),
          title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: playlist.ownerName.isNotEmpty ? Text('Por ${playlist.ownerName}') : null,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlaylistDetailScreen(playlistId: playlist.id, initialName: playlist.name),
            ),
          ),
        );
      },
    );
  }
}
