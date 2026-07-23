import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/finances.dart';
import '../../services/finances_service.dart';
import '../../utils/colors.dart';
import 'finance_history.dart';

class CoupleFinancesScreen extends StatefulWidget {
  const CoupleFinancesScreen({super.key});

  @override
  State<CoupleFinancesScreen> createState() => _CoupleFinancesScreenState();
}

class _CoupleFinancesScreenState extends State<CoupleFinancesScreen> {
  final FinancesService _service = FinancesService();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'es_ES',
    symbol: r'$',
    decimalDigits: 2,
  );

  List<Expense> _expenses = [];
  CoupleData? _coupleData;
  Budget? _currentBudget;
  bool _loading = true;
  String? _error;

  ExpenseCategory? _selectedCategoryFilter;
  DateTime? _selectedMonthFilter;
  double _monthlyBudget = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Obtener datos de pareja
      final couple = await _service.getCouple(forceRefresh: true);
      _coupleData = couple;
      _monthlyBudget = couple.monthlyBudget;

      // Obtener gastos
      final expenses = await _service.getExpenses(forceRefresh: true);
      _expenses = expenses;

      // Obtener presupuesto del mes actual
      final monthYear =
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
      try {
        final budget = await _service.getBudget(monthYear);
        _currentBudget = budget;
        _monthlyBudget = budget.amount;
      } catch (_) {
        // Budget no existe para este mes
        _currentBudget = null;
      }

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  String get _currentMonthYear =>
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

  DateTime get _budgetMonth {
    final base = _selectedMonthFilter ?? DateTime.now();
    return DateTime(base.year, base.month);
  }

  double get _budgetMonthSpent => _spentForMonth(_budgetMonth);

  double get _budgetDifference => _monthlyBudget - _budgetMonthSpent;

  bool get _isOverBudget =>
      _monthlyBudget > 0 && _budgetMonthSpent > _monthlyBudget;

  double get _budgetProgress {
    if (_monthlyBudget <= 0) return 0;
    return (_budgetMonthSpent / _monthlyBudget).clamp(0.0, 1.0);
  }

  double get _weeklySpent {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return _expenses
        .where((e) => !e.date.isBefore(startOfWeek))
        .fold(0, (sum, e) => sum + e.amount);
  }

  double get _totalSpent => _expenses.fold(0, (sum, e) => sum + e.amount);

  List<DateTime> get _availableMonths {
    final set = <DateTime>{};
    for (final expense in _expenses) {
      set.add(DateTime(expense.date.year, expense.date.month));
    }
    final months = set.toList()..sort((a, b) => b.compareTo(a));
    return months;
  }

  List<Expense> get _visibleExpenses {
    var filtered = _expenses.where((expense) {
      final categoryMatch =
          _selectedCategoryFilter == null ||
          expense.category == _selectedCategoryFilter;

      final monthMatch =
          _selectedMonthFilter == null ||
          (expense.date.year == _selectedMonthFilter!.year &&
              expense.date.month == _selectedMonthFilter!.month);

      return categoryMatch && monthMatch;
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  double _spentForMonth(DateTime month) {
    return _expenses
        .where(
          (expense) =>
              expense.date.year == month.year &&
              expense.date.month == month.month,
        )
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _showBudgetDialog() async {
    final budgetCtrl = TextEditingController(
      text: _monthlyBudget.toStringAsFixed(2),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Presupuesto mensual'),
        content: TextField(
          controller: budgetCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monto objetivo del mes',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.violeta,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final value = double.tryParse(budgetCtrl.text.replaceAll(',', '.'));
      if (value == null || value <= 0) {
        _showErrorSnackbar('Ingresa un presupuesto válido mayor a 0.');
      } else {
        try {
          await _service.setBudget(
            _currentMonthYear,
            amount: value,
          );
          setState(() => _monthlyBudget = value);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Presupuesto actualizado'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          _showErrorSnackbar(e.toString().replaceAll('Exception: ', ''));
        }
      }
    }

    budgetCtrl.dispose();
  }

  Future<void> _showExpenseSheet({Expense? editing}) async {
    final isEditing = editing != null;

    final titleCtrl = TextEditingController(text: editing?.title ?? '');
    final amountCtrl = TextEditingController(
      text: editing == null ? '' : editing.amount.toStringAsFixed(2),
    );
    final noteCtrl = TextEditingController(text: editing?.note ?? '');

    ExpenseCategory selectedCategory =
        editing?.category ?? ExpenseCategory.groceries;
    DateTime selectedDate = editing?.date ?? DateTime.now();
    bool _isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.88,
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Editar gasto' : 'Nuevo gasto',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.violeta,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: titleCtrl,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Concepto',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: amountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Monto',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<ExpenseCategory>(
                              value: selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Categoría',
                                border: OutlineInputBorder(),
                              ),
                              items: ExpenseCategory.values
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        '${c.emoji} ${c.display}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setSheetState(
                                  () => selectedCategory = value,
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Fecha: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setSheetState(
                                        () => selectedDate = picked,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.event),
                                  label: const Text('Cambiar'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: noteCtrl,
                              maxLines: 2,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Nota (opcional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSaving
                                    ? null
                                    : () async {
                                        final title = titleCtrl.text.trim();
                                        final amount = double.tryParse(
                                          amountCtrl.text.replaceAll(',', '.'),
                                        );

                                        if (title.isEmpty ||
                                            amount == null ||
                                            amount <= 0) {
                                          _showErrorSnackbar(
                                            'Completa concepto y monto válido.',
                                          );
                                          return;
                                        }

                                        setSheetState(() => _isSaving = true);

                                        try {
                                          if (isEditing) {
                                            await _service.updateExpense(
                                              editing.gastoId,
                                              title: title,
                                              amount: amount,
                                              note: noteCtrl.text.trim()
                                                      .isEmpty
                                                  ? null
                                                  : noteCtrl.text.trim(),
                                            );
                                          } else {
                                            await _service.createExpense(
                                              title: title,
                                              amount: amount,
                                              date: selectedDate,
                                              category: selectedCategory,
                                              createdBy:
                                                  _coupleData?.user1.email ??
                                                      '',
                                              note: noteCtrl.text.trim()
                                                      .isEmpty
                                                  ? null
                                                  : noteCtrl.text.trim(),
                                            );
                                          }

                                          if (mounted) {
                                            await _loadData();
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  isEditing
                                                      ? '✅ Gasto actualizado'
                                                      : '✅ Gasto guardado',
                                                ),
                                                backgroundColor:
                                                    AppColors.success,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            _showErrorSnackbar(
                                              e
                                                  .toString()
                                                  .replaceAll('Exception: ', ''),
                                            );
                                          }
                                        }

                                        setSheetState(() => _isSaving = false);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.violeta,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  disabledBackgroundColor:
                                      Colors.grey.shade300,
                                ),
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.save_rounded),
                                label: Text(
                                  isEditing
                                      ? 'Guardar cambios'
                                      : 'Guardar gasto',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  Future<void> _confirmDeleteExpense(Expense expense) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Deseas eliminar "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (accepted == true) {
      try {
        await _service.deleteExpense(expense.gastoId);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Gasto eliminado'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        _showErrorSnackbar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Widget _buildFilterCard() {
    final monthFormat = DateFormat('MMMM yyyy', 'es_ES');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: TextStyle(
              color: AppColors.violeta,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<ExpenseCategory?>(
            value: _selectedCategoryFilter,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<ExpenseCategory?>(
                value: null,
                child: Text('Todas las categorías'),
              ),
              ...ExpenseCategory.values.map(
                (category) => DropdownMenuItem<ExpenseCategory?>(
                  value: category,
                  child: Text('${category.emoji} ${category.display}'),
                ),
              ),
            ],
            onChanged: (value) =>
                setState(() => _selectedCategoryFilter = value),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<DateTime?>(
            value: _selectedMonthFilter,
            decoration: const InputDecoration(
              labelText: 'Mes',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<DateTime?>(
                value: null,
                child: Text('Todos los meses'),
              ),
              ..._availableMonths.map(
                (month) => DropdownMenuItem<DateTime?>(
                  value: month,
                  child: Text(_capitalize(monthFormat.format(month))),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _selectedMonthFilter = value),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedCategoryFilter = null;
                  _selectedMonthFilter = null;
                });
              },
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('Limpiar filtros'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard() {
    final monthLabel = _capitalize(
      DateFormat('MMMM yyyy', 'es_ES').format(_budgetMonth),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isOverBudget
              ? AppColors.error.withValues(alpha: 0.40)
              : AppColors.success.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isOverBudget
                    ? Icons.warning_amber_rounded
                    : Icons.track_changes_rounded,
                color: _isOverBudget ? AppColors.error : AppColors.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Presupuesto de $monthLabel',
                  style: TextStyle(
                    color: AppColors.violeta,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: _showBudgetDialog,
                child: const Text('Editar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_currency.format(_budgetMonthSpent)} / ${_currency.format(_monthlyBudget)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: _budgetProgress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isOverBudget ? AppColors.error : AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isOverBudget
                ? 'Excedido por ${_currency.format(_budgetDifference.abs())}'
                : 'Disponible: ${_currency.format(_budgetDifference)}',
            style: TextStyle(
              color: _isOverBudget ? AppColors.error : AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.query_stats_rounded, color: AppColors.violeta),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Historico mensual',
                  style: TextStyle(
                    color: AppColors.violeta,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Chip(
                label: const Text('Maqueta'),
                backgroundColor: AppColors.lavanda.withOpacity(0.55),
                side: BorderSide(color: AppColors.violeta.withOpacity(0.14)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Vista previa para revisar como se ha comportado el gasto por mes. Aqui luego conectaremos el back.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 152,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _historyPreviews.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = _historyPreviews[index];
                final progress = item.budget <= 0
                    ? 0.0
                    : (item.spent / item.budget).clamp(0.0, 1.0);
                final overBudget = item.spent > item.budget;

                return Container(
                  width: 220,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        item.color.withOpacity(0.95),
                        item.color.withOpacity(0.72),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: item.color.withOpacity(0.20),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.monthLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            overBudget
                                ? Icons.warning_rounded
                                : Icons.check_circle_rounded,
                            color: Colors.white.withOpacity(0.92),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.highlight,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_currency.format(item.spent)} / ${_currency.format(item.budget)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          minHeight: 9,
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.20),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            overBudget ? Colors.white : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.grisCalido.withOpacity(0.50),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.violeta.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HistoryMetric(
                    label: 'Meses mostrados',
                    value: '${_historyPreviews.length}',
                    icon: Icons.calendar_month_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HistoryMetric(
                    label: 'Con sobrecosto',
                    value:
                        '${_historyPreviews.where((e) => e.spent > e.budget).length}',
                    icon: Icons.trending_up_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFF9),
      appBar: AppBar(
        title: const Text('Finanzas de Pareja'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.violeta,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FinanceHistoryScreen()),
              );
            },
            icon: const Icon(Icons.timeline_rounded),
            label: const Text('Historico'),
            style: TextButton.styleFrom(foregroundColor: AppColors.violeta),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseSheet(),
        backgroundColor: AppColors.violeta,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Anotar gasto'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                    children: [
                      _SummaryCard(
                        totalSpent: _totalSpent,
                        weeklySpent: _weeklySpent,
                        currency: _currency,
                      ),
                      const SizedBox(height: 14),
                      _buildBudgetCard(),
                      const SizedBox(height: 14),
                      _buildFilterCard(),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: ExpenseCategory.values.map((category) {
                          final colorValue = Color(category.colorValue);
                          double total = 0;
                          for (final expense in _expenses) {
                            if (expense.category == category) {
                              total += expense.amount;
                            }
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colorValue.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorValue.withOpacity(0.30),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(category.emoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(
                                  '${category.display}: ${_currency.format(total)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: colorValue,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Movimientos',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.violeta,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 10),
                      if (_visibleExpenses.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _expenses.isEmpty
                                ? 'Aún no hay gastos. Toca "Anotar gasto" para empezar.'
                                : 'No hay resultados para esos filtros.',
                          ),
                        )
                      else
                        ..._visibleExpenses.map(
                          (expense) => _ExpenseTile(
                            expense: expense,
                            currency: _currency,
                            onEdit: () {
                              _showExpenseSheet(editing: expense);
                            },
                            onDelete: () => _confirmDeleteExpense(expense),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalSpent;
  final double weeklySpent;
  final NumberFormat currency;

  const _SummaryCard({
    required this.totalSpent,
    required this.weeklySpent,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.violeta.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.violeta.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.pie_chart_rounded,
              color: AppColors.violeta,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gasto total',
                  style: TextStyle(
                    color: AppColors.violeta,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currency.format(totalSpent),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Esta semana: ${currency.format(weeklySpent)}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final NumberFormat currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseTile({
    required this.expense,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorValue = Color(expense.category.colorValue);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorValue.withOpacity(0.12),
            child: Text(
              expense.category.emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(expense.date) +
                      (expense.note != null ? ' · ${expense.note}' : ''),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(expense.amount),
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: colorValue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HistoryMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.violeta, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}
