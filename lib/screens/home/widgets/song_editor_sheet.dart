import 'package:flutter/material.dart';

import '../../../models/song_of_week.dart';
import '../../../utils/colors.dart';

class SongEditorSheet extends StatefulWidget {
  final SongOfWeek? current;
  final VoidCallback onRandom;
  final void Function(String title, String artista, String link) onSave;

  const SongEditorSheet({
    super.key,
    required this.current,
    required this.onRandom,
    required this.onSave,
  });

  @override
  State<SongEditorSheet> createState() => _SongEditorSheetState();
}

class _SongEditorSheetState extends State<SongEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _artistaCtrl;
  late final TextEditingController _linkCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.current?.title ?? '');
    _artistaCtrl = TextEditingController(text: widget.current?.artista ?? '');
    _linkCtrl = TextEditingController(text: widget.current?.link ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistaCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe al menos el título')),
      );
      return;
    }
    widget.onSave(title, _artistaCtrl.text.trim(), _linkCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('🎵', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Canción de la semana',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.violeta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: widget.onRandom,
              icon: const Text('🎲', style: TextStyle(fontSize: 16)),
              label: const Text('Elegir una canción aleatoria'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.violeta,
                side: BorderSide(color: AppColors.violeta.withOpacity(0.4), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'o pon una manual',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade200)),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(_titleCtrl, 'Título de la canción', 'Ej: Espera y Suspira'),
            const SizedBox(height: 12),
            _buildField(_artistaCtrl, 'Artista', 'Ej: Los Panchos'),
            const SizedBox(height: 12),
            _buildField(
              _linkCtrl,
              'Link de Spotify (opcional)',
              'https://open.spotify.com/track/...',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Guardar canción'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.violeta, width: 1.5),
        ),
      ),
    );
  }
}