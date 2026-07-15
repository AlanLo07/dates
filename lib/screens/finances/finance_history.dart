import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/colors.dart';

class FinanceHistoryScreen extends StatelessWidget {
  const FinanceHistoryScreen({super.key});

  static final List<_HistoryMonthPreview> _historyPreviews = const [
    _HistoryMonthPreview(
      monthLabel: 'Julio 2026',
      spent: 284.40,
      budget: 300.00,
      highlight: 'Casi al limite',
      color: Color(0xFF4CAF50),
      tag: 'Control estable',
    ),
    _HistoryMonthPreview(
      monthLabel: 'Junio 2026',
      spent: 352.10,
      budget: 320.00,
      highlight: 'Se supero el presupuesto',
      color: Color(0xFFE57373),
      tag: 'Mes de exceso',
    ),
    _HistoryMonthPreview(
      monthLabel: 'Mayo 2026',
      spent: 218.75,
      budget: 300.00,
      highlight: 'Buen control',
      color: Color(0xFF6A88D6),
      tag: 'Ahorro',
    ),
    _HistoryMonthPreview(
      monthLabel: 'Abril 2026',
      spent: 267.90,
      budget: 300.00,
      highlight: 'En rango',
      color: Color(0xFFE1A95F),
      tag: 'Balanceado',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'es_ES',
      symbol: r'$',
      decimalDigits: 2,
    );

    final avgSpent = _historyPreviews.isEmpty
        ? 0.0
        : _historyPreviews.fold<double>(0, (sum, item) => sum + item.spent) /
            _historyPreviews.length;
    final overBudgetCount =
        _historyPreviews.where((item) => item.spent > item.budget).length;
    final bestMonth = _historyPreviews.reduce(
      (a, b) => a.spent < b.spent ? a : b,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFF9),
      appBar: AppBar(
        title: const Text('Historico de finanzas'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.violeta,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
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
                        'Historico mensual',
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
                  'Vista premium de la evolucion de gastos, con grafico y timeline visual. Luego aqui se conectara el back.',
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
                      value: '${_historyPreviews.length}',
                      icon: Icons.calendar_month_rounded,
                    ),
                    _HistoryMiniStat(
                      label: 'Promedio',
                      value: money.format(avgSpent),
                      icon: Icons.ssid_chart_rounded,
                    ),
                    _HistoryMiniStat(
                      label: 'Excesos',
                      value: '$overBudgetCount',
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Tendencia de gasto',
            subtitle: 'Maquetacion visual sin datos reales',
            trailing: Chip(
              label: const Text('Barras'),
              backgroundColor: AppColors.lavanda.withOpacity(0.45),
              side: BorderSide(color: AppColors.violeta.withOpacity(0.12)),
            ),
          ),
          const SizedBox(height: 12),
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
                    children: _historyPreviews.map((item) {
                      final progress = item.budget <= 0
                          ? 0.0
                          : (item.spent / item.budget).clamp(0.0, 1.15);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                money.format(item.spent),
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
                                  heightFactor: progress.clamp(0.10, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          item.color.withOpacity(0.95),
                                          item.color.withOpacity(0.65),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.monthShort,
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
                    _LegendDot(color: AppColors.success, label: 'Dentro del presupuesto'),
                    const SizedBox(width: 16),
                    _LegendDot(color: AppColors.error, label: 'Excedido'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Timeline mensual',
            subtitle: 'Tarjetas premium para lectura rapida',
            trailing: Chip(
              label: const Text('Historial'),
              backgroundColor: AppColors.celeste.withOpacity(0.22),
              side: BorderSide(color: AppColors.celeste.withOpacity(0.35)),
            ),
          ),
          const SizedBox(height: 12),
          ..._historyPreviews.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final progress = item.budget <= 0 ? 0.0 : (item.spent / item.budget).clamp(0.0, 1.0);
            final overBudget = item.spent > item.budget;
            final isLast = index == _historyPreviews.length - 1;

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
                          color: item.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: item.color.withOpacity(0.30),
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
                            color: item.color.withOpacity(0.22),
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
                          color: overBudget
                              ? AppColors.error.withOpacity(0.18)
                              : item.color.withOpacity(0.16),
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
                                  item.monthLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.violeta,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: item.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  item.tag,
                                  style: TextStyle(
                                    color: item.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.highlight,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${money.format(item.spent)} gastado de ${money.format(item.budget)}',
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
                              backgroundColor: AppColors.grisCalido.withOpacity(0.8),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                overBudget ? AppColors.error : item.color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                overBudget ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                                size: 18,
                                color: overBudget ? AppColors.error : AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                overBudget
                                    ? 'Supero el presupuesto mensual'
                                    : 'Dentro del rango esperado',
                                style: TextStyle(
                                  color: overBudget ? AppColors.error : AppColors.success,
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
      ),
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

class _HistoryMonthPreview {
  final String monthLabel;
  final double spent;
  final double budget;
  final String highlight;
  final Color color;
  final String tag;

  const _HistoryMonthPreview({
    required this.monthLabel,
    required this.spent,
    required this.budget,
    required this.highlight,
    required this.color,
    required this.tag,
  });

  String get monthShort {
    final parts = monthLabel.split(' ');
    if (parts.isEmpty) {
      return monthLabel;
    }
    return parts.first.substring(0, parts.first.length.clamp(0, 3));
  }
}
