import 'package:flutter/material.dart';

import '../../../utils/animations.dart';
import '../../../widgets/motion/motion_pressable.dart';
import '../models/wedding_option.dart';

class WeddingOptionCard extends StatelessWidget {
  final WeddingOption option;
  final Color accentColor;

  const WeddingOptionCard({
    super.key,
    required this.option,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return MotionPressable(
      pressedScale: 0.97,
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        if (option.screen != null) {
          Navigator.of(context).push(
            createRoute(option.screen!, motion: AppRouteMotion.sharedAxisX),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('¡Próximamente! 💍')));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: option.color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(option.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              option.titulo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: accentColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                option.subtitulo,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}