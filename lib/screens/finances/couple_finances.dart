import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/colors.dart';
import 'finance_history.dart';

class CoupleFinancesScreen extends StatefulWidget {
  const CoupleFinancesScreen({super.key});

  @override
  State<CoupleFinancesScreen> createState() => _CoupleFinancesScreenState();
}

class _CoupleFinancesScreenState extends State<CoupleFinancesScreen> {
  final List<_ExpenseEntry> _entries = [
    _ExpenseEntry(
      title: 'Spotify Duo',
      amount: 14.99,
      date: DateTime.now().subtract(const Duration(days: 3)),
      category: ExpenseCategory.subscriptions,
      note: 'Pago mensual',
    ),
    _ExpenseEntry(
      title: 'Supermercado semana',
      amount: 38.50,
      date: DateTime.now().subtract(const Duration(days: 2)),
      category: ExpenseCategory.groceries,
    ),
    _ExpenseEntry(
      title: 'Ahorro viaje playa',
      amount: 120.00,
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: ExpenseCategory.vacations,
    ),
    _ExpenseEntry(
      title: 'Cena aniversario',
      amount: 45.90,
      date: DateTime.now().subtract(const Duration(days: 6)),
      category: ExpenseCategory.dateNights,
    ),
  ];

  ExpenseCategory? _selectedCategoryFilter;
  DateTime? _selectedMonthFilter;
  double _monthlyBudget = 300.0;
  final List<_HistoryMonthPreview> _historyPreviews = const [
    _HistoryMonthPreview(
      monthLabel: 'Julio 2026',
      spent: 284.40,
      budget: 300.00,
      highlight: 'Casi al limite',
      color: Color(0xFF4CAF50),
    ),
    _HistoryMonthPreview(
      monthLabel: 'Junio 2026',
      spent: 352.10,
      budget: 320.00,
      highlight: 'Se supero el presupuesto',
      color: Color(0xFFE57373),
    ),
    _HistoryMonthPreview(
      monthLabel: 'Mayo 2026',
      spent: 218.75,
      budget: 300.00,
      highlight: 'Buen control',
      color: Color(0xFF6A88D6),
    ),
  ];

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'es_ES',
    symbol: r'$',
    decimalDigits: 2,
  );

  double get _totalSpent => _entries.fold(0, (sum, e) => sum + e.amount);

  DateTime get _budgetMonth {
    final base = _selectedMonthFilter ?? DateTime.now();
    return DateTime(base.year, base.month);
  }

  double get _budgetMonthSpent => _spentForMonth(_budgetMonth);

  double get _budgetDifference => _monthlyBudget - _budgetMonthSpent;

  bool get _isOverBudget =>
      _monthlyBudget > 0 && _budgetMonthSpent > _monthlyBudget;

  double get _budgetProgress {
    if (_monthlyBudget <= 0) {
      return 0;
    }
    return (_budgetMonthSpent / _monthlyBudget).clamp(0.0, 1.0);
  }

  double get _weeklySpent {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return _entries
        .where((e) => !e.date.isBefore(startOfWeek))
        .fold(0, (sum, e) => sum + e.amount);
  }

  List<DateTime> get _availableMonths {
    final set = <DateTime>{};
    for (final entry in _entries) {
      set.add(DateTime(entry.date.year, entry.date.month));
    }
    final months = set.toList()..sort((a, b) => b.compareTo(a));
    return months;
  }

  List<_ExpenseEntry> get _visibleEntries {
    var filtered = _entries.where((entry) {
      final categoryMatch =
          _selectedCategoryFilter == null ||
          entry.category == _selectedCategoryFilter;

      final monthMatch =
          _selectedMonthFilter == null ||
          (entry.date.year == _selectedMonthFilter!.year &&
              entry.date.month == _selectedMonthFilter!.month);

      return categoryMatch && monthMatch;
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  double _totalByCategory(ExpenseCategory category) {
    return _entries
        .where((e) => e.category == category)
        .fold(0, (sum, e) => sum + e.amount);
  }

  double _spentForMonth(DateTime month) {
    return _entries
        .where(
          (entry) =>
              entry.date.year == month.year && entry.date.month == month.month,
        )
        .fold(0, (sum, entry) => sum + entry.amount);
  }

  void _notifyBudgetIfExceeded({
    required DateTime month,
    required double before,
    required double after,
  }) {
    if (_monthlyBudget <= 0) {
      return;
    }

    final exceededNow = before <= _monthlyBudget && after > _monthlyBudget;
    if (!exceededNow) {
      return;
    }

    final currentBudgetMonth = _budgetMonth;
    if (month.year != currentBudgetMonth.year ||
        month.month != currentBudgetMonth.month) {
      return;
    }

    final overBy = after - _monthlyBudget;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        content: Text(
          'Presupuesto excedido por ${_currency.format(overBy)} en ${DateFormat('MMMM yyyy', 'es_ES').format(month)}',
        ),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ingresa un presupuesto valido mayor a 0.'),
            ),
          );
        }
      } else {
        setState(() => _monthlyBudget = value);
      }
    }

    budgetCtrl.dispose();
  }

  Future<void> _showExpenseSheet({
    _ExpenseEntry? editing,
    int? sourceIndex,
  }) async {
    final isEditing = editing != null && sourceIndex != null;

    final titleCtrl = TextEditingController(text: editing?.title ?? '');
    final amountCtrl = TextEditingController(
      text: editing == null ? '' : editing.amount.toStringAsFixed(2),
    );
    final noteCtrl = TextEditingController(text: editing?.note ?? '');

    ExpenseCategory selectedCategory =
        editing?.category ?? ExpenseCategory.groceries;
    DateTime selectedDate = editing?.date ?? DateTime.now();

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
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Concepto',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: selectedCategory.conceptSuggestions
                                  .map(
                                    (suggestion) => ActionChip(
                                      label: Text(suggestion),
                                      onPressed: () {
                                        titleCtrl.text = suggestion;
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 12),
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
                                labelText: 'Categoria',
                                border: OutlineInputBorder(),
                              ),
                              items: ExpenseCategory.values
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setSheetState(() => selectedCategory = value);
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
                                onPressed: () {
                                  final title = titleCtrl.text.trim();
                                  final amount = double.tryParse(
                                    amountCtrl.text.replaceAll(',', '.'),
                                  );

                                  if (title.isEmpty ||
                                      amount == null ||
                                      amount <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Completa concepto y monto valido.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final updatedEntry = _ExpenseEntry(
                                    title: title,
                                    amount: amount,
                                    date: selectedDate,
                                    category: selectedCategory,
                                    note: noteCtrl.text.trim().isEmpty
                                        ? null
                                        : noteCtrl.text.trim(),
                                  );

                                  final affectedMonth = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                  );
                                  final beforeSpent = _spentForMonth(
                                    affectedMonth,
                                  );

                                  setState(() {
                                    if (isEditing) {
                                      _entries[sourceIndex!] = updatedEntry;
                                    } else {
                                      _entries.insert(0, updatedEntry);
                                    }
                                  });

                                  final afterSpent = _spentForMonth(
                                    affectedMonth,
                                  );
                                  _notifyBudgetIfExceeded(
                                    month: affectedMonth,
                                    before: beforeSpent,
                                    after: afterSpent,
                                  );

                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.violeta,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                icon: const Icon(Icons.save_rounded),
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

  Future<void> _confirmDeleteEntry(_ExpenseEntry entry) async {
    final sourceIndex = _entries.indexOf(entry);
    if (sourceIndex < 0) {
      return;
    }

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Deseas eliminar "${entry.title}"?'),
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
      setState(() => _entries.removeAt(sourceIndex));
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
              labelText: 'Categoria',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<ExpenseCategory?>(
                value: null,
                child: Text('Todas las categorias'),
              ),
              ...ExpenseCategory.values.map(
                (category) => DropdownMenuItem<ExpenseCategory?>(
                  value: category,
                  child: Text(category.label),
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
      body: ListView(
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
              final color = category.color;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(category.icon, size: 18, color: color),
                    const SizedBox(width: 6),
                    Text(
                      '${category.label}: ${_currency.format(_totalByCategory(category))}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.violeta,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (_visibleEntries.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _entries.isEmpty
                    ? 'Aun no hay gastos. Toca "Anotar gasto" para empezar.'
                    : 'No hay resultados para esos filtros.',
              ),
            )
          else
            ..._visibleEntries.map(
              (entry) => _ExpenseTile(
                entry: entry,
                currency: _currency,
                onEdit: () {
                  final sourceIndex = _entries.indexOf(entry);
                  if (sourceIndex >= 0) {
                    _showExpenseSheet(editing: entry, sourceIndex: sourceIndex);
                  }
                },
                onDelete: () => _confirmDeleteEntry(entry),
              ),
            ),
        ],
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
  final _ExpenseEntry entry;
  final NumberFormat currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseTile({
    required this.entry,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
            backgroundColor: entry.category.color.withOpacity(0.12),
            child: Icon(entry.category.icon, color: entry.category.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(entry.date) +
                      (entry.note != null ? ' · ${entry.note}' : ''),
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
                currency.format(entry.amount),
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: entry.category.color,
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

enum ExpenseCategory {
  subscriptions(
    'Suscripciones',
    Icons.subscriptions_rounded,
    Color(0xFF6A88D6),
  ),
  groceries('Supermercado', Icons.shopping_basket_rounded, Color(0xFF4CAF50)),
  transport('Transporte', Icons.directions_car_rounded, Color(0xFF42A5F5)),
  dateNights('Citas y salidas', Icons.wine_bar_rounded, Color(0xFFE57373)),
  home('Casa', Icons.home_rounded, Color(0xFF8D6E63)),
  health('Salud y bienestar', Icons.spa_rounded, Color(0xFF26A69A)),
  vacations('Vacaciones', Icons.flight_takeoff_rounded, Color(0xFFFF8A65)),
  gifts('Regalos', Icons.card_giftcard_rounded, Color(0xFFAB47BC)),
  pets('Mascotas', Icons.pets_rounded, Color(0xFF8D6E63)),
  hobbies('Gustos personales', Icons.favorite_rounded, Color(0xFFE91E63)),
  savings('Ahorro', Icons.savings_rounded, Color(0xFF5C6BC0)),
  others('Otros', Icons.receipt_long_rounded, Color(0xFF8D6E63));

  const ExpenseCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  List<String> get conceptSuggestions {
    switch (this) {
      case ExpenseCategory.subscriptions:
        return ['Netflix', 'Spotify Duo', 'Google One', 'Canva Pro'];
      case ExpenseCategory.groceries:
        return [
          'Supermercado semanal',
          'Mercado de frutas',
          'Productos de limpieza',
        ];
      case ExpenseCategory.transport:
        return ['Gasolina', 'Uber', 'Parqueadero', 'Peajes'];
      case ExpenseCategory.dateNights:
        return [
          'Cena aniversario',
          'Cine',
          'Cafe y postres',
          'Salida de fin de semana',
        ];
      case ExpenseCategory.home:
        return ['Arriendo', 'Servicios', 'Internet hogar', 'Mantenimiento'];
      case ExpenseCategory.health:
        return ['Farmacia', 'Consulta medica', 'Gimnasio', 'Vitaminas'];
      case ExpenseCategory.vacations:
        return ['Reserva hotel', 'Tiquetes', 'Tour', 'Fondo viaje'];
      case ExpenseCategory.gifts:
        return ['Cumpleanos', 'Aniversario', 'Detalle sorpresa', 'Flores'];
      case ExpenseCategory.pets:
        return ['Concentrado', 'Veterinario', 'Bano y peluqueria', 'Juguetes'];
      case ExpenseCategory.hobbies:
        return ['Videojuego', 'Libro', 'Ropa', 'Curso online'];
      case ExpenseCategory.savings:
        return [
          'Ahorro emergencia',
          'Meta carro',
          'Meta apartamento',
          'Fondo boda',
        ];
      case ExpenseCategory.others:
        return [
          'Imprevisto',
          'Comision bancaria',
          'Pago pendiente',
          'Otro gasto',
        ];
    }
  }
}

class _ExpenseEntry {
  final String title;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? note;

  _ExpenseEntry({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.note,
  });
}

class _HistoryMonthPreview {
  final String monthLabel;
  final double spent;
  final double budget;
  final String highlight;
  final Color color;

  const _HistoryMonthPreview({
    required this.monthLabel,
    required this.spent,
    required this.budget,
    required this.highlight,
    required this.color,
  });
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
