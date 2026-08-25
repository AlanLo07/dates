// lib/screens/checklist/checklist_menu_screen.dart
import 'package:flutter/material.dart';

import '../../models/checklist.dart';
import '../../services/checklists_service.dart';
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
  final ChecklistsService _service = ChecklistsService();
  List<ChecklistBoard> _boards = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadBoards({bool seed = true}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (seed) {
        await _service.seedDefaults();
      }
      final boards = await _service.getChecklists();
      if (!mounted) return;
      setState(() => _boards = boards);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createBoard() async {
    final result = await showCreateChecklistDialog(context);
    if (result == null) return;
    try {
      await _service.createChecklist(
        titulo: result.titulo,
        kind: result.kind,
        emoji: result.emoji,
        usaGrupos: result.usaGrupos,
      );
      await _loadBoards(seed: false);
    } catch (e) {
      _showError('No se pudo crear el checklist: $e');
    }
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
    if (ok != true) return;
    setState(() => _boards.removeWhere((b) => b.id == board.id));
    try {
      await _service.deleteChecklist(board.id);
    } catch (e) {
      _showError('No se pudo eliminar el checklist: $e');
      await _loadBoards(seed: false);
    }
  }

  Future<void> _openBoard(ChecklistBoard board) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChecklistDetailScreen(checklistId: board.id),
      ),
    );
    if (mounted) await _loadBoards(seed: false);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisCalido,
      appBar: AppBar(
        title: const Text('Checklists'),
        backgroundColor: AppColors.violeta,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : () => _loadBoards(seed: false),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBoard,
        backgroundColor: AppColors.violeta,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Checklist', style: TextStyle(color: Colors.white)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _boards.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _boards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No se pudieron cargar los checklists.\n$_error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.violeta.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.violeta,
                ),
                onPressed: () => _loadBoards(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_boards.isEmpty) {
      return Center(
        child: Text(
          'No tienes checklists aún.\nToca "Checklist" para crear el primero.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.violeta.withValues(alpha: 0.6)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadBoards(seed: false),
      child: ListView.separated(
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
