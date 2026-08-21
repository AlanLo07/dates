// lib/screens/checklist/widgets/create_checklist_dialog.dart
import 'package:flutter/material.dart';

import '../../../models/checklist.dart';
import '../../../utils/colors.dart';

class CreateChecklistResult {
  final String titulo;
  final ChecklistKind kind;
  final String emoji;
  final bool usaGrupos;

  CreateChecklistResult({
    required this.titulo,
    required this.kind,
    required this.emoji,
    required this.usaGrupos,
  });
}

Future<CreateChecklistResult?> showCreateChecklistDialog(
  BuildContext context,
) {
  return showDialog<CreateChecklistResult>(
    context: context,
    builder: (_) => const _CreateChecklistDialog(),
  );
}

class _CreateChecklistDialog extends StatefulWidget {
  const _CreateChecklistDialog();

  @override
  State<_CreateChecklistDialog> createState() =>
      _CreateChecklistDialogState();
}

class _CreateChecklistDialogState extends State<_CreateChecklistDialog> {
  final _tituloCtrl = TextEditingController();
  final _emojiCtrl = TextEditingController();
  ChecklistKind _kind = ChecklistKind.personalizado;
  bool _usaGrupos = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  void _onKindChanged(ChecklistKind kind) {
    setState(() {
      _kind = kind;
      _usaGrupos = kind.usesGroupsByDefault;
      if (_emojiCtrl.text.isEmpty) {
        _emojiCtrl.text = kind.emoji;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo checklist'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _tituloCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej. Súper de la quincena',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emojiCtrl,
              maxLength: 2,
              decoration: const InputDecoration(
                labelText: 'Emoji (opcional)',
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tipo',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ChecklistKind.values.map((k) {
                final selected = k == _kind;
                return ChoiceChip(
                  label: Text('${k.emoji} ${k.display}'),
                  selected: selected,
                  onSelected: (_) => _onKindChanged(k),
                  selectedColor: k.color.withValues(alpha: 0.25),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Organizar por departamentos'),
              subtitle: const Text('Ej. lácteos, limpieza, ropa...'),
              value: _usaGrupos,
              onChanged: (v) => setState(() => _usaGrupos = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.violeta),
          onPressed: () {
            final titulo = _tituloCtrl.text.trim();
            if (titulo.isEmpty) return;
            Navigator.of(context).pop(
              CreateChecklistResult(
                titulo: titulo,
                kind: _kind,
                emoji: _emojiCtrl.text.trim().isEmpty
                    ? _kind.emoji
                    : _emojiCtrl.text.trim(),
                usaGrupos: _usaGrupos,
              ),
            );
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
