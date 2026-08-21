// lib/screens/checklist/checklist_menu_screen.dart
import 'package:flutter/material.dart';

import '../../models/checklist.dart';
import '../../utils/colors.dart';
import 'checklist_detail_screen.dart';
import 'widgets/checklist_board_card.dart';
import 'widgets/create_checklist_dialog.dart';

class ChecklistMenuScreen extends StatefulWidget {
  const ChecklistMenuScreen({super.key});

  @override
  State<ChecklistMenuScreen> createState() => _ChecklistMenuScreenState();
}

class _ChecklistMenuScreenState extends State<ChecklistMenuScreen> {
  // Datos de ejemplo en memoria. Cuando exista el servicio, esto se
  // reemplaza por una carga real (ChecklistService.getBoards()).
  late final List<ChecklistBoard> _boards = _buildSeedBoards();

  List<ChecklistBoard> _buildSeedBoards() {
    final supermercado = ChecklistBoard(
      id: 'b_super',
      titulo: 'Súper de la semana',
      kind: ChecklistKind.supermercado,
      grupos: defaultSupermercadoGroups(),
      items: [
        ChecklistItem(
          id: 'i1',
          nombre: 'Leche deslactosada',
          groupId: 'g_lacteos',
          prioridad: ItemPriority.alta,
          precio: 32,
          emoji: '🥛',
        ),
        ChecklistItem(
          id: 'i2',
          nombre: 'Manzanas',
          groupId: 'g_frutas',
          prioridad: ItemPriority.media,
          precio: 45,
          emoji: '🍎',
        ),
        ChecklistItem(
          id: 'i3',
          nombre: 'Jabón para trastes',
          groupId: 'g_limpieza',
          prioridad: ItemPriority.baja,
          precio: 28,
        ),
      ],
    );

    final viaje = ChecklistBoard(
      id: 'b_viaje',
      titulo: 'Viaje a la playa',
      kind: ChecklistKind.viaje,
      grupos: defaultViajeGroups(),
      items: [
        ChecklistItem(
          id: 'i4',
          nombre: 'Pasaportes',
          groupId: 'g_documentos',
          prioridad: ItemPriority.alta,
          emoji: '🛂',
        ),
        ChecklistItem(
          id: 'i5',
          nombre: 'Bloqueador solar',
          groupId: 'g_cosmeticos',
          prioridad: ItemPriority.media,
          precio: 95,
        ),
      ],
    );

    final deseos = ChecklistBoard(
      id: 'b_deseos',
      titulo: 'Cosas que queremos',
      kind: ChecklistKind.deseos,
      usaGrupos: false,
      items: [
        ChecklistItem(
          id: 'i6',
          nombre: 'Consola de videojuegos',
          prioridad: ItemPriority.media,
          precio: 9500,
          emoji: '🎮',
        ),
        ChecklistItem(
          id: 'i7',
          nombre: 'Bicicleta',
          prioridad: ItemPriority.baja,
          precio: 4200,
          emoji: '🚲',
        ),
      ],
    );

    return [supermercado, viaje, deseos];
  }

  Future<void> _createBoard() async {
    final result = await showCreateChecklistDialog(context);
    if (result == null) return;
    setState(() {
      _boards.add(
        ChecklistBoard(
          id: 'b_${DateTime.now().microsecondsSinceEpoch}',
          titulo: result.titulo,
          kind: result.kind,
          emoji: result.emoji,
          usaGrupos: result.usaGrupos,
          grupos: result.kind == ChecklistKind.supermercado
              ? defaultSupermercadoGroups()
              : result.kind == ChecklistKind.viaje
              ? defaultViajeGroups()
              : [],
        ),
      );
    });
  }

  Future<void> _deleteBoard(ChecklistBoard board) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar checklist'),
        content: Text('¿Eliminar "${board.titulo}" y todos sus items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _boards.removeWhere((b) => b.id == board.id));
    }
  }

  Future<void> _openBoard(ChecklistBoard board) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChecklistDetailScreen(board: board),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisCalido,
      appBar: AppBar(
        title: const Text('Checklists'),
        backgroundColor: AppColors.violeta,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBoard,
        backgroundColor: AppColors.violeta,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Checklist', style: TextStyle(color: Colors.white)),
      ),
      body: _boards.isEmpty
          ? Center(
              child: Text(
                'No tienes checklists aún.\nToca "Checklist" para crear el primero.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.violeta.withValues(alpha: 0.6)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _boards.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final board = _boards[index];
                return ChecklistBoardCard(
                  board: board,
                  onTap: () => _openBoard(board),
                  onDelete: () => _deleteBoard(board),
                );
              },
            ),
    );
  }
}
