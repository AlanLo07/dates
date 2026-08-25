// lib/screens/checklist/checklist_detail_screen.dart
import 'package:flutter/material.dart';

import '../../models/checklist.dart';
import '../../services/checklists_service.dart';
import '../../utils/colors.dart';
import 'widgets/checklist_item_tile.dart';
import 'widgets/item_editor_sheet.dart';

class ChecklistDetailScreen extends StatefulWidget {
  final String checklistId;

  const ChecklistDetailScreen({super.key, required this.checklistId});

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends State<ChecklistDetailScreen> {
  final ChecklistsService _service = ChecklistsService();
  ChecklistBoard? _board;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBoard();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadBoard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final board = await _service.getChecklist(widget.checklistId);
      if (!mounted) return;
      setState(() => _board = board);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addItem() async {
    final board = _board;
    if (board == null) return;
    final result = await showItemEditorSheet(
      context,
      board: board,
      service: _service,
    );
    if (result == null) return;
    try {
      await _service.createItem(
        board.id,
        ChecklistItem(
          id: '',
          nombre: result.nombre,
          groupId: result.groupId,
          prioridad: result.prioridad,
          precio: result.precio,
          emoji: result.emoji,
        ),
      );
      await _loadBoard();
    } catch (e) {
      _showError('No se pudo agregar el item: $e');
    }
  }

  Future<void> _editItem(ChecklistItem item) async {
    final board = _board;
    if (board == null) return;
    final result = await showItemEditorSheet(
      context,
      board: board,
      existing: item,
      service: _service,
    );
    if (result == null) return;
    try {
      await _service.updateItem(board.id, item.id, {
        'nombre': result.nombre,
        'groupId': result.groupId,
        'prioridad': result.prioridad.name,
        'precio': result.precio,
        'emoji': result.emoji,
      });
      await _loadBoard();
    } catch (e) {
      _showError('No se pudo actualizar el item: $e');
    }
  }

  Future<void> _toggleItem(ChecklistItem item, bool? value) async {
    final board = _board;
    if (board == null) return;
    final comprado = value ?? false;
    setState(() => item.comprado = comprado);
    try {
      await _service.setComprado(board.id, item.id, comprado);
    } catch (e) {
      setState(() => item.comprado = !comprado);
      _showError('No se pudo actualizar el item: $e');
    }
  }

  Future<void> _deleteItem(ChecklistItem item) async {
    final board = _board;
    if (board == null) return;
    setState(() => board.items.removeWhere((i) => i.id == item.id));
    try {
      await _service.deleteItem(board.id, item.id);
    } catch (e) {
      _showError('No se pudo eliminar el item: $e');
      await _loadBoard();
    }
  }

  Future<void> _confirmReset() async {
    final board = _board;
    if (board == null) return;
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
    if (ok != true) return;
    try {
      await _service.resetChecklist(board.id);
      await _loadBoard();
    } catch (e) {
      _showError('No se pudo reiniciar el checklist: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = _board;
    if (_loading && board == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && board == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checklist')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No se pudo cargar el checklist.\n$_error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.violeta,
                  ),
                  onPressed: _loadBoard,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (board == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final hasPrecio = board.items.any((i) => i.precio != null);
    final grupos = board.gruposOrdenados;

    return Scaffold(
      backgroundColor: AppColors.grisCalido,
      appBar: AppBar(
        title: Text('${board.emoji} ${board.titulo}'),
        backgroundColor: board.color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Reiniciar checklist',
            icon: const Icon(Icons.replay_rounded),
            onPressed: board.items.isEmpty ? null : _confirmReset,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        backgroundColor: board.color,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Item', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBoard,
        child: Column(
          children: [
            _buildSummary(board, hasPrecio),
            Expanded(
              child: board.items.isEmpty
                  ? _buildEmptyState(board)
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 100, top: 8),
                      children: [
                        for (final grupo in grupos)
                          _buildGroupSection(board, grupo),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ChecklistBoard board, bool hasPrecio) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: board.color.withValues(alpha: 0.15),
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
                board.totalItems == 0
                    ? 'Sin items todavía'
                    : '${board.compradosCount}/${board.totalItems} listos',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.violeta,
                ),
              ),
              if (hasPrecio)
                Text(
                  '\$${board.precioPendiente.toStringAsFixed(0)} pendiente de \$${board.precioTotal.toStringAsFixed(0)}',
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
              value: board.totalItems == 0 ? 0 : board.progreso,
              minHeight: 8,
              backgroundColor: board.color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(board.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ChecklistBoard board) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(board.emoji, style: const TextStyle(fontSize: 48)),
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

  Widget _buildGroupSection(ChecklistBoard board, ChecklistGroup? grupo) {
    final items = board.itemsByGroup(grupo?.id);
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
