import 'package:flutter/material.dart';

class WeddingCountdownHeader extends StatelessWidget {
  final DateTime weddingDate;
  final Color accentColor;

  const WeddingCountdownHeader({
    super.key,
    required this.weddingDate,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final days = weddingDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('💍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            days > 0 ? '¡Faltan $days días!' : '¡Hoy es el gran día! 🎉',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${weddingDate.day.toString().padLeft(2, '0')}-'
            '${weddingDate.month.toString().padLeft(2, '0')}-'
            '${weddingDate.year}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}