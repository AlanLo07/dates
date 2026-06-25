import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeAnimatedEntryCard extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration fadeDuration;
  final Duration slideDuration;
  final Duration stagger;

  const HomeAnimatedEntryCard({
    super.key,
    required this.index,
    required this.child,
    required this.fadeDuration,
    required this.slideDuration,
    required this.stagger,
  });

  @override
  Widget build(BuildContext context) {
    final delay = stagger * index;

    // Mantiene la entrada escalonada para todos los cards del menu.
    return child
        .animate()
        .fadeIn(delay: delay, duration: fadeDuration)
        .slideY(begin: 0.10, delay: delay, duration: slideDuration);
  }
}