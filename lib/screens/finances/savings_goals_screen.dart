import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/savings_goals.dart';
import '../../services/savings_goals_service.dart';
import '../../services/wedding_service.dart';
import '../../utils/colors.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  final SavingsGoalsService _service = SavingsGoalsService();
  final WeddingService _weddingService = WeddingService();
  SavingsBoard? _board;
  WeddingMeta? _wedding;
  bool _loading = true;
  bool _working = false;
  String? _error;

  NumberFormat _currency(String currency) => NumberFormat.currency(
    locale: 'es_CO',
    name: currency,
    decimalDigits: currency == 'COP' ? 0 : 2,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final board = await _service.getBoard();
      WeddingMeta? wedding;
      try {
        wedding = await _weddingService.getPrimaryWedding();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _board = board;
        _wedding = wedding;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _showGoalDialog({SavingsGoal? goal}) async {
    final nameController = TextEditingController(text: goal?.name ?? '');
    final amountController = TextEditingController(
      text: goal == null ? '' : goal.targetAmount.toStringAsFixed(0),
    );
    var linkToWedding = goal?.isLinkedToWeddingBudget ?? false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(goal == null ? 'Nueva meta' : 'Editar meta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la meta',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Monto objetivo',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_wedding != null) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: linkToWedding,
                    title: const Text('Vincular al presupuesto de boda'),
                    subtitle: Text(_wedding!.nombre),
                    onChanged: (value) => setDialogState(
                      () => linkToWedding = value ?? false,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final name = nameController.text.trim();
      final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
      if (name.isEmpty || amount == null || amount <= 0) {
        _showMessage('Escribe un nombre y un monto válido mayor que cero.', error: true);
      } else {
        await _runAction(() async {
          if (goal == null) {
            await _service.createGoal(
              name: name,
              targetAmount: amount,
              bodaId: linkToWedding ? _wedding?.id : null,
            );
          } else {
            await _service.updateGoal(
              goal.goalId,
              name: name,
              targetAmount: amount,
              bodaId: linkToWedding ? _wedding?.id : null,
              removeWeddingLink: !linkToWedding && goal.isLinkedToWeddingBudget,
            );
          }
          await _load(showLoading: false);
          _showMessage(goal == null ? 'Meta creada.' : 'Meta actualizada.');
        });
      }
    }
    nameController.dispose();
    amountController.dispose();
  }

  Future<void> _showAmountDialog({required bool withdrawal}) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(withdrawal ? 'Retirar del colchón' : 'Registrar ahorro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLength: 160,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: withdrawal ? 'Motivo del retiro' : 'Nota (opcional)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(withdrawal ? 'Retirar' : 'Guardar ahorro'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
      final note = noteController.text.trim();
      if (amount == null || amount <= 0 || (withdrawal && note.isEmpty)) {
        _showMessage(
          withdrawal
              ? 'Indica un monto válido y el motivo del retiro.'
              : 'Ingresa un monto válido mayor que cero.',
          error: true,
        );
      } else {
        await _runAction(() async {
          if (withdrawal) {
            await _service.withdraw(
              amount: amount,
              date: DateTime.now().toUtc(),
              note: note,
            );
            await _load(showLoading: false);
            _showMessage('Retiro registrado en el colchón.');
          } else {
            final result = await _service.addContribution(
              amount: amount,
              date: DateTime.now().toUtc(),
              note: note.isEmpty ? null : note,
            );
            await _load(showLoading: false);
            if (result.completedGoal != null && mounted) {
              await _showCelebration(result);
            } else if (result.sentToCushion > 0) {
              _showMessage('El sobrante se agregó al colchón.');
            } else {
              _showMessage('Ahorro registrado.');
            }
          }
        });
      }
    }
    amountController.dispose();
    noteController.dispose();
  }

  Future<void> _showCelebration(SavingsOperationResult result) async {
    final completedGoal = result.completedGoal;
    if (completedGoal == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.celebration_rounded, size: 42, color: AppColors.success),
        title: const Text('¡Meta completada!'),
        content: Text(
          'Completaron “${completedGoal.name}”. '
          '${result.sentToCushion > 0 ? 'El sobrante se agregó al colchón.' : 'La siguiente meta ya está lista.'}',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveGoal(SavingsGoal goal) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivar meta'),
        content: Text('“${goal.name}” y sus movimientos se conservarán en el historial.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await _runAction(() async {
        await _service.archiveGoal(goal.goalId);
        await _load(showLoading: false);
        _showMessage('Meta archivada.');
      });
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _reorderGoals(int oldIndex, int newIndex) async {
    final current = List<SavingsGoal>.from(_board!.pendingGoals);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = current.removeAt(oldIndex);
    current.insert(newIndex, moved);
    setState(() => _working = true);
    try {
      final board = await _service.reorderGoals(
        current.map((goal) => goal.goalId).toList(),
      );
      if (mounted) setState(() => _board = board);
    } catch (error) {
      await _load(showLoading: false);
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _openHistory({String? goalId, bool cushion = false}) async {
    final board = _board;
    if (board == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavingsHistoryScreen(
          service: _service,
          currency: board.currency,
          goals: board.pendingGoals + board.completedGoals + board.archivedGoals,
          initialGoalId: goalId,
          initialCushion: cushion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFF9),
      appBar: AppBar(
        title: const Text('Metas de ahorro'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.violeta,
        actions: [
          IconButton(
            tooltip: 'Historial de movimientos',
            onPressed: _board == null ? null : () => _openHistory(),
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      floatingActionButton: _board == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _working ? null : () => _showAmountDialog(withdrawal: false),
              backgroundColor: AppColors.violeta,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.savings_outlined),
              label: const Text('Registrar ahorro'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : _board == null
          ? const SizedBox.shrink()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _summaryCard(_board!),
                  const SizedBox(height: 14),
                  _cascadeCard(_board!),
                  const SizedBox(height: 14),
                  _cushionCard(_board!),
                  const SizedBox(height: 22),
                  _sectionHeader(
                    'Metas',
                    trailing: IconButton.filledTonal(
                      tooltip: 'Crear meta',
                      onPressed: _working ? null : () => _showGoalDialog(),
                      icon: const Icon(Icons.add),
                    ),
                  ),
                  if (_board!.pendingGoals.isEmpty)
                    _emptyPanel(
                      'Aún no hay metas pendientes',
                      'Crea una meta para comenzar la cascada de ahorro.',
                      Icons.flag_outlined,
                    )
                  else
                    _pendingGoalsList(_board!),
                  if (_board!.completedGoals.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _sectionHeader('Metas completadas'),
                    ..._board!.completedGoals.map(
                      (goal) => _goalHistoryTile(goal, completed: true),
                    ),
                  ],
                  if (_board!.archivedGoals.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _sectionHeader('Archivadas'),
                    ..._board!.archivedGoals.map(
                      (goal) => _goalHistoryTile(goal),
                    ),
                  ],
                  const SizedBox(height: 22),
                  _sectionHeader(
                    'Movimientos recientes',
                    trailing: TextButton(
                      onPressed: () => _openHistory(),
                      child: const Text('Ver todo'),
                    ),
                  ),
                  if (_board!.latestMovements.isEmpty)
                    _emptyPanel(
                      'Todavía no hay movimientos',
                      'Los aportes y retiros aparecerán aquí.',
                      Icons.receipt_long_outlined,
                    )
                  else
                    ..._board!.latestMovements.take(5).map(
                      (movement) => _MovementTile(
                        movement: movement,
                        currency: _currency(_board!.currency),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard(SavingsBoard board) {
    final currency = _currency(board.currency);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.violeta.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.success),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ahorro total', style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 3),
                Text(
                  currency.format(board.totalSaved),
                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Text(board.currency, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _cascadeCard(SavingsBoard board) {
    final currency = _currency(board.currency);
    final goal = board.activeGoal;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.violeta.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes_rounded, color: AppColors.violeta),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal == null ? 'Cascada de ahorro' : 'Meta activa · ${goal.name}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (board.cascade.isEmpty)
            Text(
              'Agrega una meta para ver el progreso de la cascada.',
              style: TextStyle(color: Colors.grey.shade700),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    for (final segment in board.cascade)
                      Expanded(
                        flex: segment.targetAmount.round().clamp(1, 1000000000),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: LinearProgressIndicator(
                            value: segment.progress,
                            minHeight: 14,
                            backgroundColor: AppColors.violeta.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              segment.goalId == goal?.goalId
                                  ? AppColors.violeta
                                  : AppColors.success,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (goal != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('${goal.progressPercent.toStringAsFixed(0)}% completado')),
                Text(
                  '${currency.format(goal.accumulatedAmount)} / ${currency.format(goal.targetAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Faltan ${currency.format(board.activeGoalRemainingAmount)}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text('No hay metas pendientes. Los ahorros van al colchón.'),
          ],
        ],
      ),
    );
  }

  Widget _cushionCard(SavingsBoard board) {
    final currency = _currency(board.currency);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.shield_outlined, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(board.cushion.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  currency.format(board.cushion.balance),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                Text('Fondo compartido para sobrantes y retiros'),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Retirar del colchón',
            onPressed: _working || board.cushion.balance <= 0
                ? null
                : () => _showAmountDialog(withdrawal: true),
            icon: const Icon(Icons.south_west_rounded),
          ),
        ],
      ),
    );
  }

  Widget _pendingGoalsList(SavingsBoard board) {
    final goals = board.pendingGoals;
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: goals.length,
      onReorder: _working ? (_, __) {} : _reorderGoals,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return Container(
          key: ValueKey(goal.goalId),
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: index == 0
                  ? AppColors.violeta.withValues(alpha: 0.32)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Icon(Icons.drag_indicator, color: Colors.grey.shade500),
                ),
              ),
              Expanded(child: _goalContent(goal, index, board)),
              PopupMenuButton<String>(
                tooltip: 'Acciones de meta',
                onSelected: (value) {
                  if (value == 'edit') _showGoalDialog(goal: goal);
                  if (value == 'history') _openHistory(goalId: goal.goalId);
                  if (value == 'archive') _archiveGoal(goal);
                },
                itemBuilder: (_) => [
                  if (!goal.isCompleted)
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  const PopupMenuItem(value: 'history', child: Text('Ver movimientos')),
                  const PopupMenuItem(value: 'archive', child: Text('Archivar')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _goalContent(SavingsGoal goal, int index, SavingsBoard board) {
    final currency = _currency(board.currency);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: index == 0
                  ? AppColors.violeta.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.12),
              child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                goal.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (index == 0)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text('Activa', style: TextStyle(color: AppColors.violeta, fontSize: 12)),
              ),
            if (goal.isLinkedToWeddingBudget)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.favorite, color: AppColors.error, size: 15),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (goal.progressPercent / 100).clamp(0.0, 1.0),
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
          backgroundColor: Colors.grey.shade200,
          color: index == 0 ? AppColors.violeta : AppColors.success,
        ),
        const SizedBox(height: 5),
        Text(
          '${currency.format(goal.accumulatedAmount)} / ${currency.format(goal.targetAmount)} · faltan ${currency.format(goal.remainingAmount)}',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
      ],
    );
  }

  Widget _goalHistoryTile(SavingsGoal goal, {bool completed = false}) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: Icon(
        completed ? Icons.check_circle_outline : Icons.inventory_2_outlined,
        color: completed ? AppColors.success : Colors.grey,
      ),
      title: Text(goal.name),
      subtitle: Text(completed ? 'Completada' : 'Archivada'),
      trailing: IconButton(
        tooltip: 'Ver movimientos',
        onPressed: () => _openHistory(goalId: goal.goalId),
        icon: const Icon(Icons.history_rounded),
      ),
    ),
  );

  Widget _sectionHeader(String title, {Widget? trailing}) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.violeta),
        ),
      ),
      if (trailing != null) trailing,
    ],
  );

  Widget _emptyPanel(String title, String subtitle, IconData icon) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        Icon(icon, color: AppColors.violeta),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
      ],
    ),
  );
}

class SavingsHistoryScreen extends StatefulWidget {
  const SavingsHistoryScreen({
    super.key,
    required this.service,
    required this.currency,
    required this.goals,
    this.initialGoalId,
    this.initialCushion = false,
  });

  final SavingsGoalsService service;
  final String currency;
  final List<SavingsGoal> goals;
  final String? initialGoalId;
  final bool initialCushion;

  @override
  State<SavingsHistoryScreen> createState() => _SavingsHistoryScreenState();
}

class _SavingsHistoryScreenState extends State<SavingsHistoryScreen> {
  SavingsMovementPage? _page;
  String? _selectedGoalId;
  bool _cushion = false;
  bool _loading = true;
  String? _error;
  final NumberFormat _dateFormat = DateFormat('dd/MM/yyyy · HH:mm');

  NumberFormat get _currency => NumberFormat.currency(
    locale: 'es_CO',
    name: widget.currency,
    decimalDigits: widget.currency == 'COP' ? 0 : 2,
  );

  @override
  void initState() {
    super.initState();
    _selectedGoalId = widget.initialGoalId;
    _cushion = widget.initialCushion;
    _load();
  }

  Future<void> _load({String? cursor}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.service.getMovements(
        goalId: _cushion ? null : _selectedGoalId,
        cushion: _cushion,
        limit: 25,
        cursor: cursor,
      );
      if (!mounted) return;
      setState(() {
        _page = cursor == null || _page == null
            ? page
            : SavingsMovementPage(
                items: [..._page!.items, ...page.items],
                count: _page!.count + page.count,
                limit: page.limit,
                nextCursor: page.nextCursor,
              );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFF9),
      appBar: AppBar(
        title: const Text('Historial de ahorro'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.violeta,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _cushion ? 'COLCHON' : (_selectedGoalId ?? 'all'),
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por meta',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('Todas')),
                      const DropdownMenuItem(value: 'COLCHON', child: Text('Colchón')),
                      ...widget.goals.map(
                        (goal) => DropdownMenuItem(
                          value: goal.goalId,
                          child: Text(goal.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _cushion = value == 'COLCHON';
                        _selectedGoalId = value == null || value == 'all' || value == 'COLCHON'
                            ? null
                            : value;
                        _page = null;
                      });
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading && _page == null
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _page == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        FilledButton(onPressed: _load, child: const Text('Reintentar')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _load(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        if (_page?.items.isEmpty ?? true)
                          const Padding(
                            padding: EdgeInsets.only(top: 70),
                            child: Center(child: Text('No hay movimientos para mostrar.')),
                          )
                        else
                          ..._page!.items.map(
                            (movement) => _MovementTile(
                              movement: movement,
                              currency: _currency,
                              dateFormat: _dateFormat,
                            ),
                          ),
                        if (_page?.nextCursor != null)
                          Center(
                            child: TextButton.icon(
                              onPressed: _loading ? null : () => _load(cursor: _page!.nextCursor),
                              icon: const Icon(Icons.expand_more),
                              label: const Text('Cargar más'),
                            ),
                          ),
                        if (_loading && _page != null)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({
    required this.movement,
    required this.currency,
    this.dateFormat,
  });

  final SavingsMovement movement;
  final NumberFormat currency;
  final DateFormat? dateFormat;

  @override
  Widget build(BuildContext context) {
    final isWithdrawal = movement.movementType.toLowerCase().contains('retiro');
    final amountColor = isWithdrawal ? AppColors.error : AppColors.success;
    final date = dateFormat ?? DateFormat('dd/MM/yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: amountColor.withValues(alpha: 0.12),
            child: Icon(
              isWithdrawal ? Icons.south_west_rounded : Icons.savings_outlined,
              color: amountColor,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movement.goalName, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  movement.automaticReference ?? movement.note ?? date.format(movement.date.toLocal()),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                if (movement.userEmail != null)
                  Text(movement.userEmail!, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isWithdrawal ? '−' : '+'}${currency.format(movement.amount)}',
            style: TextStyle(color: amountColor, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
