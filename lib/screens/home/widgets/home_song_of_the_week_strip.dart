import 'package:flutter/material.dart';

import '../../../models/song_of_week.dart';

class HomeSongOfTheWeekStrip extends StatelessWidget {
  final SongOfWeek? song;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const HomeSongOfTheWeekStrip({
    super.key,
    required this.song,
    required this.isLoading,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1DB954), Color(0xFF158a3e)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1DB954).withOpacity(0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading || song == null ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('🎵', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: isLoading
                      ? _buildSkeleton()
                      : song == null
                      ? _buildEmpty()
                      : _buildSongInfo(song!),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(SongOfWeek s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'CANCIÓN DE LA SEMANA',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.70),
                letterSpacing: 1.2,
              ),
            ),
            if (s.setBy == 'random') ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '🎲 aleatoria',
                  style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.80)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          s.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (s.artista.isNotEmpty)
          Text(
            s.artista,
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 80,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Text(
      'Sin canción esta semana — toca ✏️ para agregar',
      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75)),
    );
  }
}