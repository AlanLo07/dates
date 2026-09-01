// lib/screens/checklist/widgets/item_editor_sheet.dart
import 'package:flutter/material.dart';

import '../../../models/checklist.dart';
import '../../../services/checklists_service.dart';
import '../../../utils/colors.dart';

const List<String> kQuickEmojis = [
  '🛒',
  '🍎',
  '🥛',
  '🧴',
  '👕',
  '📄',
  '💳',
  '🎮',
  '🚲',
  '👟',
  '💻',
  '🎁',
  '📷',
  '⌚',
  '🧸',
];

class ItemEditorResult {
  final String nombre;
  final String? groupId;
  final ItemPriority prioridad;
  final int prioridadOrden;
  final double? precio;
  final String? emoji;

  ItemEditorResult({
    required this.nombre,
    required this.groupId,
    required this.prioridad,
    required this.prioridadOrden,
    required this.precio,
    required this.emoji,
  });
}

Future<ItemEditorResult?> showItemEditorSheet(
  BuildContext context, {
  required ChecklistBoard board,
  required ChecklistsService service,
  ChecklistItem? existing,
}) {
  return showModalBottomSheet<ItemEditorResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _ItemEditorSheet(board: board, service: service, existing: existing),
  );
}

class _ItemEditorSheet extends StatefulWidget {
  final ChecklistBoard board;
  final ChecklistsService service;
  final ChecklistItem? existing;

  const _ItemEditorSheet({
    required this.board,
    required this.service,
    this.existing,
  });

  @override
  State<_ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<_ItemEditorSheet> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _prioridadOrdenCtrl;
  String? _groupId;
  ItemPriority _prioridad = ItemPriority.media;
  String? _emoji;
  late List<ChecklistGroup> _grupos;
  bool _creatingGroup = false;
  bool _savingGroup = false;
  final _nuevoGrupoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nombreCtrl = TextEditingController(text: e?.nombre ?? '');
    _precioCtrl = TextEditingController(
      text: e?.precio != null ? e!.precio!.toStringAsFixed(2) : '',
    );
    _groupId = e?.groupId;
    _prioridad = e?.prioridad ?? ItemPriority.media;
    _prioridadOrdenCtrl = TextEditingController(
      text: (e?.prioridadOrden ?? (widget.board.items.length + 1)).toString(),
    );
    _emoji = e?.emoji;
    _grupos = [...widget.board.grupos]..sort((a, b) => a.orden.compareTo(b.orden));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _precioCtrl.dispose();
    _prioridadOrdenCtrl.dispose();
    _nuevoGrupoCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmarNuevoGrupo() async {
    final nombre = _nuevoGrupoCtrl.text.trim();
    if (nombre.isEmpty || _savingGroup) return;
    setState(() => _savingGroup = true);
    try {
      final borrador = ChecklistGroup(
        id: '',
        nombre: nombre,
        orden: _grupos.length,
      );
      final groupId = await widget.service.createGroup(
        widget.board.id,
        borrador,
      );
      final grupo = ChecklistGroup(
        id: groupId,
        nombre: nombre,
        orden: _grupos.length,
      );
      widget.board.grupos.add(grupo);
      if (!mounted) return;
      setState(() {
        _grupos = [...widget.board.grupos];
        _groupId = grupo.id;
        _creatingGroup = false;
        _nuevoGrupoCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo crear el departamento: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingGroup = false);
    }
  }

  void _submit() {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) return;
    final precioText = _precioCtrl.text.trim().replaceAll(',', '.');
    final precio = precioText.isEmpty ? null : double.tryParse(precioText);
    final prioridadOrden = int.tryParse(_prioridadOrdenCtrl.text.trim()) ?? 1;
    Navigator.of(context).pop(
      ItemEditorResult(
        nombre: nombre,
        groupId: _groupId,
        prioridad: _prioridad,
        prioridadOrden: prioridadOrden,
        precio: precio,
        emoji: _emoji,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                isEditing ? 'Editar item' : 'Nuevo item',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: AppColors.violeta,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nombreCtrl,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  labelText: 'Nombre del item',
                  hintText: 'Ej. Leche deslactosada',
                ),
              ),
              const SizedBox(height: 12),
              if (widget.board.usaGrupos) ...[
                const Text(
                  'Departamento',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final g in _grupos)
                      ChoiceChip(
                        label: Text('${g.emoji ?? ''} ${g.nombre}'.trim()),
                        selected: _groupId == g.id,
                        onSelected: (_) => setState(() => _groupId = g.id),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: const Text('Nuevo'),
                      onPressed: () => setState(() => _creatingGroup = true),
                    ),
                  ],
                ),
                if (_creatingGroup) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nuevoGrupoCtrl,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del departamento',
                          ),
                          onSubmitted: (_) => _confirmarNuevoGrupo(),
                        ),
                      ),
                      IconButton(
                        icon: _savingGroup
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.check,
                                color: AppColors.violeta,
                              ),
                        onPressed: _savingGroup ? null : _confirmarNuevoGrupo,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
              ],
              const Text(
                'Prioridad',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ItemPriority.values.map((p) {
                  final selected = p == _prioridad;
                  return ChoiceChip(
                    label: Text(p.display),
                    selected: selected,
                    selectedColor: p.color.withValues(alpha: 0.3),
                    onSelected: (_) => setState(() => _prioridad = p),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text(
                'Orden de prioridad',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Número entero: 1 es el más importante',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _prioridadOrdenCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Orden',
                  hintText: 'Ej. 1',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _precioCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio (opcional)',
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Emoji (opcional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in kQuickEmojis)
                    ChoiceChip(
                      label: Text(e, style: const TextStyle(fontSize: 16)),
                      selected: _emoji == e,
                      onSelected: (sel) =>
                          setState(() => _emoji = sel ? e : null),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.violeta,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _submit,
                  child: Text(isEditing ? 'Guardar cambios' : 'Agregar item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
