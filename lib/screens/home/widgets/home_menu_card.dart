import 'package:flutter/material.dart';

import '../../../utils/animations.dart';
import '../../../widgets/motion/motion_pressable.dart';
import 'home_animated_entry_card.dart';

class HomeMenuCard extends StatelessWidget {
  final int index;
  final String emoji;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget destination;
  final List<Color> gradientColors;
  final Duration fadeDuration;
  final Duration slideDuration;
  final Duration stagger;

  const HomeMenuCard({
    super.key,
    required this.index,
    required this.emoji,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.destination,
    required this.gradientColors,
    required this.fadeDuration,
    required this.slideDuration,
    required this.stagger,
  });

  @override
  Widget build(BuildContext context) {
    return HomeAnimatedEntryCard(
      index: index,
      fadeDuration: fadeDuration,
      slideDuration: slideDuration,
      stagger: stagger,
      child: MotionPressable(
        pressedScale: 0.98,
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          createRoute(destination, motion: AppRouteMotion.sharedAxisX),
        ),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withOpacity(0.30),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -8,
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 64,
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.80),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.65),
                      size: 15,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}