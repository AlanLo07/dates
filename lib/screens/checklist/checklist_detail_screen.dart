// lib/screens/checklist/checklist_detail_screen.dart
import 'package:flutter/material.dart';

import '../../models/checklist.dart';
import '../../utils/colors.dart';
import 'widgets/checklist_item_tile.dart';
import 'widgets/item_editor_sheet.dart';

class ChecklistDetailScreen extends StatefulWidget {
  final ChecklistBoard board;

  const ChecklistDetailScreen({super.key, required this.board});

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends State<ChecklistDetailScreen> {
  ChecklistBoard get _board => widget.board;

  Future<void> _addItem() async {
    final result = await showItemEditorSheet(context, board: _board);
    if (result == null) return;
    setState(() {
      _board.items.add(
        ChecklistItem(
          id: 'i_${DateTime.now().microsecondsSinceEpoch}',
          nombre: result.nombre,
          groupId: result.groupId,
          prioridad: result.prioridad,
          precio: result.precio,
          emoji: result.emoji,
        ),
      );
      _board.updatedAt = DateTime.now();
    });
  }

  Future<void> _editItem(ChecklistItem item) async {
    final result = await showItemEditorSheet(
      context,
      board: _board,
      existing: item,
    );
    if (result == null) return;
    setState(() {
      item
        ..nombre = result.nombre
        ..groupId = result.groupId
        ..prioridad = result.prioridad
        ..precio = result.precio
        ..emoji = result.emoji
        ..updatedAt = DateTime.now();
    });
  }

  void _toggleItem(ChecklistItem item, bool? value) {
    setState(() {
      item.comprado = value ?? false;
      item.updatedAt = DateTime.now();
      _board.updatedAt = DateTime.now();
    });
  }

  void _deleteItem(ChecklistItem item) {
    setState(() {
      _board.items.removeWhere((i) => i.id == item.id);
      _board.updatedAt = DateTime.now();
    });
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reiniciar checklist'),
        content: const Text(
          '¿Quitar la marca de "comprado/listo" de todos los items? '
          'No se borrará ningún item.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.violeta),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _board.resetTodos());
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPrecio = _board.items.any((i) => i.precio != null);
    final grupos = _board.gruposOrdenados;

    return Scaffold(
      backgroundColor: AppColors.grisCalido,
      appBar: AppBar(
        title: Text('${_board.emoji} ${_board.titulo}'),
        backgroundColor: _board.color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Reiniciar checklist',
            icon: const Icon(Icons.replay_rounded),
            onPressed: _board.items.isEmpty ? null : _confirmReset,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        backgroundColor: _board.color,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Item', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          _buildSummary(hasPrecio),
          Expanded(
            child: _board.items.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.only(bottom: 100, top: 8),
                    children: [
                      for (final grupo in grupos) _buildGroupSection(grupo),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(bool hasPrecio) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _board.color.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _board.totalItems == 0
                    ? 'Sin items todavía'
                    : '${_board.compradosCount}/${_board.totalItems} listos',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.violeta,
                ),
              ),
              if (hasPrecio)
                Text(
                  '\$${_board.precioPendiente.toStringAsFixed(0)} pendiente de \$${_board.precioTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppColors.violeta.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _board.totalItems == 0 ? 0 : _board.progreso,
              minHeight: 8,
              backgroundColor: _board.color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(_board.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_board.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Aún no hay items',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.violeta,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Toca "Item" para agregar el primero.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.violeta.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSection(ChecklistGroup? grupo) {
    final items = _board.itemsByGroup(grupo?.id);
    if (items.isEmpty) return const SizedBox.shrink();

    final titulo = grupo?.nombre ?? 'Sin categoría';
    final emoji = grupo?.emoji ?? '📌';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.violeta.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${items.where((i) => i.comprado).length}/${items.length})',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.violeta.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  ChecklistItemTile(
                    item: items[i],
                    onToggle: (v) => _toggleItem(items[i], v),
                    onTap: () => _editItem(items[i]),
                    onDelete: () => _deleteItem(items[i]),
                  ),
                  if (i != items.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
