import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/finances.dart';
import '../../services/finances_service.dart';
import '../../utils/colors.dart';

class FinanceHistoryScreen extends StatefulWidget {
  const FinanceHistoryScreen({super.key});

  @override
  State<FinanceHistoryScreen> createState() => _FinanceHistoryScreenState();
}

class _FinanceHistoryScreenState extends State<FinanceHistoryScreen> {
  final FinancesService _service = FinancesService();
  List<FinancialHistory> _history = [];
  bool _loading = true;
  String? _error;

  final NumberFormat _money = NumberFormat.currency(
    locale: 'es_ES',
    symbol: r'$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final history = await _service.getHistory(limit: 12);
      if (mounted) {
        setState(() {
          _history = history;
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

  double get _avgSpent => _history.isEmpty
      ? 0.0
      : _history.fold<double>(0, (sum, item) => sum + item.totalSpent) /
          _history.length;

  int get _overBudgetCount =>
      _history.where((item) => item.overBudget).length;

  FinancialHistory? get _bestMonth =>
      _history.isEmpty ? null : _history.reduce((a, b) => a.totalSpent < b.totalSpent ? a : b);

  Color _getColorForMonth(FinancialHistory month) {
    if (month.overBudget) {
      return const Color(0xFFE57373);
    }
    final ratio = month.totalSpent / month.budgetAmount;
    if (ratio > 0.8) {
      return const Color(0xFFE1A95F);
    }
    if (ratio > 0.5) {
      return const Color(0xFF4CAF50);
    }
    return const Color(0xFF6A88D6);
  }

  String _getHighlightForMonth(FinancialHistory month) {
    if (month.overBudget) {
      return 'Se superó el presupuesto';
    }
    final ratio = month.totalSpent / month.budgetAmount;
    if (ratio > 0.8) {
      return 'Casi al límite';
    }
    if (ratio > 0.5) {
      return 'En rango';
    }
    return 'Buen control';
  }

  String _getTagForMonth(FinancialHistory month) {
    if (month.overBudget) {
      return 'Mes de exceso';
    }
    final ratio = month.totalSpent / month.budgetAmount;
    if (ratio > 0.8) {
      return 'Alerta';
    }
    if (ratio > 0.5) {
      return 'Balanceado';
    }
    return 'Ahorro';
  }

  String _formatMonthYear(String monthYear) {
    try {
      final date = DateTime.parse('$monthYear-01');
      return DateFormat('MMMM yyyy', 'es_ES').format(date);
    } catch (_) {
      return monthYear;
    }
  }

  String _formatMonthShort(String monthYear) {
    try {
      final date = DateTime.parse('$monthYear-01');
      return DateFormat('MMM', 'es_ES').format(date);
    } catch (_) {
      return monthYear;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFF9),
      appBar: AppBar(
        title: const Text('Histórico de finanzas'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.violeta,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
                        onPressed: _loadHistory,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 18),
                      _buildTrendSection(),
                      const SizedBox(height: 18),
                      _buildTimelineSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7F8FD7), Color(0xFF5D4A86)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.violeta.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Histórico mensual',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Evolución de gastos de los últimos ${_history.length} meses con análisis detallado.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HistoryMiniStat(
                label: 'Meses',
                value: '${_history.length}',
                icon: Icons.calendar_month_rounded,
              ),
              _HistoryMiniStat(
                label: 'Promedio',
                value: _money.format(_avgSpent),
                icon: Icons.ssid_chart_rounded,
              ),
              _HistoryMiniStat(
                label: 'Excesos',
                value: '$_overBudgetCount',
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Tendencia de gasto',
          subtitle: 'Visualización de gastos vs presupuesto',
          trailing: Chip(
            label: const Text('Barras'),
            backgroundColor: AppColors.lavanda.withOpacity(0.45),
            side: BorderSide(color: AppColors.violeta.withOpacity(0.12)),
          ),
        ),
        const SizedBox(height: 12),
        if (_history.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: Text('No hay datos disponibles'),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 210,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _history.map((item) {
                      final progress = item.budgetAmount <= 0
                          ? 0.0
                          : (item.totalSpent / item.budgetAmount)
                              .clamp(0.0, 1.15);
                      final color = _getColorForMonth(item);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                _money.format(item.totalSpent),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.violeta,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 150,
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor:
                                      progress.clamp(0.10, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          color.withOpacity(0.95),
                                          color.withOpacity(0.65),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatMonthShort(item.monthYear),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _LegendDot(
                      color: AppColors.success,
                      label: 'Dentro del presupuesto',
                    ),
                    const SizedBox(width: 16),
                    _LegendDot(
                      color: AppColors.error,
                      label: 'Excedido',
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Timeline mensual',
          subtitle: 'Detalle de cada período',
          trailing: Chip(
            label: const Text('Historial'),
            backgroundColor: AppColors.celeste.withOpacity(0.22),
            side: BorderSide(color: AppColors.celeste.withOpacity(0.35)),
          ),
        ),
        const SizedBox(height: 12),
        if (_history.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text('No hay datos disponibles'),
            ),
          )
        else
          ..._history.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final progress = item.budgetAmount <= 0
                ? 0.0
                : (item.totalSpent / item.budgetAmount).clamp(0.0, 1.0);
            final color = _getColorForMonth(item);
            final isLast = index == _history.length - 1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.30),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 128,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: item.overBudget
                              ? AppColors.error.withOpacity(0.18)
                              : color.withOpacity(0.16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 12,
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
                                  _formatMonthYear(item.monthYear),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.violeta,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _getTagForMonth(item),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getHighlightForMonth(item),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_money.format(item.totalSpent)} gastado de ${_money.format(item.budgetAmount)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 10,
                              value: progress,
                              backgroundColor:
                                  AppColors.grisCalido.withOpacity(0.8),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                item.overBudget
                                    ? AppColors.error
                                    : color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                item.overBudget
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_rounded,
                                size: 18,
                                color: item.overBudget
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.overBudget
                                    ? 'Superó el presupuesto mensual'
                                    : 'Dentro del rango esperado',
                                style: TextStyle(
                                  color: item.overBudget
                                      ? AppColors.error
                                      : AppColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.violeta,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        trailing,
      ],
    );
  }
}

class _HistoryMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HistoryMiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
