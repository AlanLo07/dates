import 'package:flutter/material.dart';

import '../../../utils/colors.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.violeta.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('💌', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nuestro Lugar Seguro',
                  style: TextStyle(
                    color: AppColors.violeta,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '¿Qué hacemos hoy?',
                  style: TextStyle(
                    color: AppColors.violeta.withOpacity(0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Text('🌸', style: TextStyle(fontSize: 28)),
        ],
      ),
    );
  }
}