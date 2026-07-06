// lib/screens/games/games_menu.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/animations.dart';
import '../../utils/colors.dart';
import '../../widgets/motion/ambient_orbs_background.dart';
import '../../widgets/motion/motion_pressable.dart';
import 'kama_screen.dart';

import 'dice_screen.dart';
import 'wheel_screen.dart';

class GamesMenuScreen extends StatelessWidget {
  const GamesMenuScreen({super.key});

  static const List<_GameItem> _games = [
    _GameItem(
      emoji: '🎲',
      title: 'Dado del deseo',
      subtitle: 'Posición, parte del cuerpo y prenda al azar',
      gradientStart: Color(0xFFF48FB1),
      gradientEnd: Color(0xFFCE6D8B),
      shadowColor: Color(0xFFCE6D8B),
      comingSoon: false,
    ),
    _GameItem(
      emoji: '🎡',
      title: 'Ruleta de retos',
      subtitle: 'Gira y descubre qué hacerle a tu pareja',
      gradientStart: Color(0xFFB0B6E8),
      gradientEnd: Color(0xFF796B9B),
      shadowColor: Color(0xFF796B9B),
      comingSoon: false,
    ),
    _GameItem(
      emoji: '🃏',
      title: 'Kamasutra',
      subtitle: 'Tarjetas con posiciones por nivel de dificultad',
      gradientStart: Color(0xFFF0A07A),
      gradientEnd: Color(0xFFBF5B2E),
      shadowColor: Color(0xFFBF5B2E),
      comingSoon: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavanda,
      appBar: AppBar(
        title: const Text(
          'Juegos para dos 🔒',
          style: TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.violeta),
        elevation: 1,
      ),
      body: AmbientOrbsBackground(
        colors: const [Color(0xFFF48FB1), Color(0xFFB0B6E8), Color(0xFFF0A07A)],
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
          // ── Intro ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.violeta.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Su espacio privado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.violeta,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Juegos para explorar juntos, a su ritmo y con total confianza.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Cards de juegos ───────────────────────────────────────────────
          ...List.generate(_games.length, (i) {
            final game = _games[i];
            return _AnimatedGameCard(
              index: i,
              game: game,
              onTap: game.comingSoon ? null : () => _navigate(context, game),
            );
          }),

          const SizedBox(height: 16),

          // ── Próximamente footer ───────────────────────────────────────────
          Center(
            child: Text(
              'Más juegos próximamente 💌',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.violeta.withOpacity(0.45),
                letterSpacing: 0.3,
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, _GameItem game) {
    Widget destination;
    switch (game.title) {
      case 'Kamasutra':
        destination = const KamaScreen();
        break;
      case 'Dado del deseo':
        destination = const DiceScreen();
        break;
      case 'Ruleta de retos':
        destination = const WheelScreen();
        break;
      // Los otros se agregarán cuando estén listos
      default:
        return;
    }
    Navigator.of(
      context,
    ).push(createRoute(destination, motion: AppRouteMotion.sharedAxisX));
  }
}

// ── Modelo de dato ─────────────────────────────────────────────────────────────
class _GameItem {
  final String emoji;
  final String title;
  final String subtitle;
  final Color gradientStart;
  final Color gradientEnd;
  final Color shadowColor;
  final bool comingSoon;

  const _GameItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
    required this.shadowColor,
    required this.comingSoon,
  });
}

// ── Card animada ───────────────────────────────────────────────────────────────
class _AnimatedGameCard extends StatefulWidget {
  static const Duration kFadeDuration = Duration(milliseconds: 360);
  static const Duration kSlideDuration = Duration(milliseconds: 430);
  static const Duration kStagger = Duration(milliseconds: 80);

  final int index;
  final _GameItem game;
  final VoidCallback? onTap;

  const _AnimatedGameCard({
    required this.index,
    required this.game,
    required this.onTap,
  });

  @override
  State<_AnimatedGameCard> createState() => _AnimatedGameCardState();
}

class _AnimatedGameCardState extends State<_AnimatedGameCard> {
  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final isEnabled = widget.onTap != null;
    final delay = _AnimatedGameCard.kStagger * widget.index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MotionPressable(
        onTap: isEnabled ? widget.onTap : () => _showComingSoon(context),
        pressedScale: 0.98,
        borderRadius: BorderRadius.circular(20),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.75,
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [game.gradientStart, game.gradientEnd],
              ),
              boxShadow: [
                BoxShadow(
                  color: game.shadowColor.withOpacity(isEnabled ? 0.30 : 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Emoji decorativo de fondo
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: Text(
                    game.emoji,
                    style: TextStyle(
                      fontSize: 70,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                ),

                    // Contenido principal
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          // Ícono
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                game.emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Texto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      game.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (game.comingSoon) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Text(
                                          'Pronto',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  game.subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.80),
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Flecha
                          Icon(
                            isEnabled
                                ? Icons.arrow_forward_ios_rounded
                                : Icons.lock_outline_rounded,
                            color: Colors.white.withOpacity(0.60),
                            size: 15,
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    )
        // Mantiene la secuencia de entrada sin AnimationController manual.
        .animate()
        .fadeIn(delay: delay, duration: _AnimatedGameCard.kFadeDuration)
        .slideY(
          begin: 0.10,
          delay: delay,
          duration: _AnimatedGameCard.kSlideDuration,
        );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('⏳ '),
            Text('${widget.game.title} estará disponible pronto'),
          ],
        ),
        backgroundColor: AppColors.violeta,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
