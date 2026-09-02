import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/spotify.dart';

const Color _spotifyGreen = Color(0xFF1DB954);

/// Fila compacta para listar un track de Spotify en pantallas de detalle.
class SpotifyTrackTile extends StatelessWidget {
  final SpotifyTrack track;
  final int? index;
  final VoidCallback? onTap;

  const SpotifyTrackTile({
    super.key,
    required this.track,
    this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: SizedBox(
        width: 44,
        height: 44,
        child: index != null
            ? Center(
                child: Text(
                  '${index! + 1}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: track.imageUrl.isEmpty
                    ? Container(
                        color: _spotifyGreen.withValues(alpha: 0.12),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: _spotifyGreen,
                          size: 18,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: track.imageUrl,
                        fit: BoxFit.cover,
                      ),
              ),
      ),
      title: Text(
        track.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: _spotifyGreen),
    );
  }
}
