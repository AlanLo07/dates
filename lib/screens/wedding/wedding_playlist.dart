// lib/screens/wedding/wedding_playlist.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/boda.dart';

const Color _rose = Color(0xFFE91E63);
const List<String> _momentos = ['Entrada', 'Primer baile', 'Vals', 'Fiesta'];

class WeddingPlaylistScreen extends StatefulWidget {
  const WeddingPlaylistScreen({super.key});
  @override
  State<WeddingPlaylistScreen> createState() => _WeddingPlaylistScreenState();
}

class _WeddingPlaylistScreenState extends State<WeddingPlaylistScreen> {
  final List<CancionBoda> _canciones = [
    CancionBoda(
      id: '1',
      titulo: 'Perfect',
      artista: 'Ed Sheeran',
      momento: 'Entrada',
    ),
    CancionBoda(
      id: '2',
      titulo: "Can't Help Falling in Love",
      artista: 'Elvis Presley',
      momento: 'Primer baile',
    ),
    CancionBoda(
      id: '3',
      titulo: 'La Bikina',
      artista: 'Los Panchos',
      momento: 'Vals',
    ),
    CancionBoda(
      id: '4',
      titulo: 'Uptown Funk',
      artista: 'Bruno Mars',
      momento: 'Fiesta',
    ),
  ];

  Future<void> _abrirSpotify(String link) async {
    if (link.isEmpty) return;
    final uri = Uri.parse(link);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  Map<String, List<CancionBoda>> get _grouped {
    final m = <String, List<CancionBoda>>{};
    for (final momento in _momentos) {
      m[momento] = _canciones.where((c) => c.momento == momento).toList();
    }
    // Cualquier momento fuera de la lista fija (por si acaso)
    for (final c in _canciones) {
      if (!_momentos.contains(c.momento)) {
        m.putIfAbsent(c.momento, () => []).add(c);
      }
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC),
      appBar: AppBar(
        title: const Text('Playlist', style: TextStyle(color: _rose)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _rose),
            onPressed: () => _mostrarAgregar(context),
          ),
        ],
      ),
      body: _canciones.isEmpty
          ? _buildEmpty()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _grouped.entries.where((e) => e.value.isNotEmpty).map((
                entry,
              ) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            _iconoMomento(entry.key),
                            size: 16,
                            color: _rose,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _rose,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...entry.value.map((c) => _buildCancionCard(c)),
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
            ),
    );
  }

  IconData _iconoMomento(String momento) {
    switch (momento) {
      case 'Entrada':
        return Icons.church_outlined;
      case 'Primer baile':
        return Icons.favorite_outline;
      case 'Vals':
        return Icons.family_restroom_outlined;
      case 'Fiesta':
        return Icons.celebration_outlined;
      default:
        return Icons.music_note_outlined;
    }
  }

  Widget _buildCancionCard(CancionBoda c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.music_note_rounded, color: _rose, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (c.artista.isNotEmpty)
                  Text(
                    c.artista,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          if (c.link.isNotEmpty)
            GestureDetector(
              onTap: () => _abrirSpotify(c.link),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Color(0xFF1DB954),
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎵', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Agrega su primera canción',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _mostrarAgregar(BuildContext context) {
    final tituloCtrl = TextEditingController();
    final artistaCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    String momento = 'Fiesta';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nueva canción',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _rose,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tituloCtrl,
                decoration: InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: artistaCtrl,
                decoration: InputDecoration(
                  labelText: 'Artista',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkCtrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Link de Spotify (opcional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Momento',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _momentos.map((m) {
                  final selected = momento == m;
                  return GestureDetector(
                    onTap: () => setLocal(() => momento = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? _rose : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        m,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (tituloCtrl.text.trim().isEmpty) return;
                    setState(() {
                      _canciones.add(
                        CancionBoda(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          titulo: tituloCtrl.text.trim(),
                          artista: artistaCtrl.text.trim(),
                          momento: momento,
                          link: linkCtrl.text.trim(),
                        ),
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Agregar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
