// lib/screens/home.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'input.dart';
import '../utils/animations.dart';
import '../utils/colors.dart';
import 'phrases.dart';
import 'calendar.dart';
import 'memories.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Iconos del status bar oscuros para que se lean sobre el fondo lavanda
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      // Sin AppBar — el header vive dentro del body con el mismo color de fondo
      backgroundColor: AppColors.lavanda,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header integrado (mismo color que fondo) ────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Ícono de sobre
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.violeta.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('💌', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Título + subtítulo
                  Column(
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
                  const Spacer(),
                  // Flor decorativa
                  const Text('🌸', style: TextStyle(fontSize: 28)),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Lista de cards ───────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  _buildMenuCard(
                    context,
                    index: 0,
                    emoji: '✨',
                    icon: Icons.favorite_rounded,
                    title: 'Generar Cita',
                    subtitle: '¿Qué hacemos hoy? Que la suerte decida',
                    destination: const InputScreen(),
                    gradientColors: const [
                      Color(0xFFB0B6E8),
                      Color(0xFF796B9B),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildMenuCard(
                    context,
                    index: 1,
                    emoji: '📅',
                    icon: Icons.calendar_month_rounded,
                    title: 'Fechas Importantes',
                    subtitle: 'Nuestros momentos más especiales',
                    destination: const CalendarScreen(),
                    gradientColors: const [
                      Color(0xFFA9D1DF),
                      Color(0xFF6BAED6),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildMenuCard(
                    context,
                    index: 2,
                    emoji: '💬',
                    icon: Icons.auto_stories_rounded,
                    title: "De mí pa' ti",
                    subtitle: 'Adivina la frase que te dedico',
                    destination: const PhrasesScreen(),
                    gradientColors: const [
                      Color(0xFFD8C9E7),
                      Color(0xFF9C8DC4),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildMenuCard(
                    context,
                    index: 3,
                    emoji: '🗺️',
                    icon: Icons.explore_rounded,
                    title: 'Nuestras Aventuras',
                    subtitle: 'Checklist de todos los lugares que fuimos',
                    destination: ExperienceMenuScreen(),
                    gradientColors: const [
                      Color(0xFFFFCDD2),
                      Color(0xFFE57373),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required int index,
    required String emoji,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget destination,
    required List<Color> gradientColors,
  }) {
    return _AnimatedCard(
      index: index,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(createRoute(destination)),
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
              // Emoji decorativo de fondo semitransparente
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
              // Contenido principal
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    // Ícono en caja semitransparente
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
                    // Texto
                    Expanded(
                      child: Column(
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
                    // Flecha
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

// ── Animación de entrada escalonada ──────────────────────────────────────────
class _AnimatedCard extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedCard({required this.index, required this.child});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
