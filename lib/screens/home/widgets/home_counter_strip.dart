import 'package:flutter/material.dart';

import '../../../utils/colors.dart';

class HomeCounterStrip extends StatelessWidget {
  final Stream<Duration> stream;
  final Duration initial;

  const HomeCounterStrip({
    super.key,
    required this.stream,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lavanda,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: StreamBuilder<Duration>(
        stream: stream,
        initialData: initial,
        builder: (_, snap) {
          final d = snap.data!;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HomeCounterBox(value: d.inDays, label: 'Días'),
              const SizedBox(width: 6),
              _HomeCounterBox(value: d.inHours % 24, label: 'Hrs'),
              const SizedBox(width: 6),
              _HomeCounterBox(value: d.inMinutes % 60, label: 'Min'),
              const SizedBox(width: 6),
              _HomeCounterBox(value: d.inSeconds % 60, label: 'Seg'),
              const SizedBox(width: 10),
              const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('juntos', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('desde', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(
                    '18 · 12 · 2023',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.violeta,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeCounterBox extends StatelessWidget {
  final int value;
  final String label;

  const _HomeCounterBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grisCalido,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.violeta,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }
}