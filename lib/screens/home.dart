// lib/screens/home.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'input.dart';
import '../utils/animations.dart';
import '../utils/colors.dart';
import 'calendar.dart';
import 'memories.dart';
import 'type_phrases.dart';
import 'wedding.dart';

const String _heroImageUrl =
    'https://planes-crud-stack-images-052869941322.s3.us-east-2.amazonaws.com/assets/beso.jpeg';

const _anniversaryDate = (year: 2023, month: 12, day: 18);
final _weddingUnlockDate = DateTime(2026, 12, 18);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Duration _together;
  late Stream<Duration> _counterStream;

  @override
  void initState() {
    super.initState();
    _together = _calcDuration();
    _counterStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => _calcDuration(),
    );
  }

  Duration _calcDuration() {
    final start = DateTime(
      _anniversaryDate.year,
      _anniversaryDate.month,
      _anniversaryDate.day,
    );
    return DateTime.now().difference(start);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.lavanda,
      body: SafeArea(
        child: SingleChildScrollView(
          // ── El Column hijo de SingleChildScrollView NUNCA debe tener
          //    mainAxisSize: max ni hijos con Expanded/Flexible ──────────
          child: Column(
            mainAxisSize: MainAxisSize.min, // ← clave: se ajusta al contenido
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Foto de portada
              _HeroHeader(imageUrl: _heroImageUrl),

              // 2. Contador
              _CounterStrip(stream: _counterStream, initial: _together),

              const SizedBox(height: 12),

              // 3. Header "Nuestro Lugar Seguro" — Row, no Column
              Padding(
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
                      child: const Center(
                        child: Text('💌', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Expanded funciona bien dentro de Row
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
              ),

              const SizedBox(height: 20),

              // 4. Cards — sin Expanded, sin ListView independiente
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                      destination: const TypePhrasesScreen(),
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
                    const SizedBox(height: 14),
                    if (DateTime.now().isAfter(_weddingUnlockDate))
                      _buildMenuCard(
                        context,
                        index: 4,
                        emoji: '💍',
                        icon: Icons.favorite,
                        title: 'Nuestra Boda',
                        subtitle: 'Todo en un solo lugar',
                        destination: const WeddingScreen(),
                        gradientColors: const [
                          Color(0xFFF8BBD0),
                          Color(0xFFE91E63),
                        ],
                      )
                    else
                      _buildLockedWeddingCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedWeddingCard() {
    final daysLeft = _weddingUnlockDate.difference(DateTime.now()).inDays;
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB0B6E8), Color(0xFF796B9B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF796B9B).withOpacity(0.25),
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
              '💍',
              style: TextStyle(
                fontSize: 64,
                color: Colors.white.withOpacity(0.15),
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Nuestra Boda',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        daysLeft > 0
                            ? 'Se desbloquea en $daysLeft días'
                            : 'Próximamente...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '🔒 pronto',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
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

// ── Animación escalonada ─────────────────────────────────────────────────────
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

// ── Hero ─────────────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final String imageUrl;
  const _HeroHeader({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                Container(color: AppColors.violeta.withOpacity(0.4)),
            errorWidget: (_, __, ___) => Container(
              color: AppColors.violeta.withOpacity(0.4),
              child: const Icon(
                Icons.favorite,
                size: 48,
                color: Colors.white54,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.65),
                  Colors.black.withOpacity(0.05),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 18,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, Nati 💌',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Hoy es un buen día para hacer algo especial',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contador ──────────────────────────────────────────────────────────────────
class _CounterStrip extends StatelessWidget {
  final Stream<Duration> stream;
  final Duration initial;
  const _CounterStrip({required this.stream, required this.initial});

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
              _CounterBox(value: d.inDays, label: 'Días'),
              const SizedBox(width: 6),
              _CounterBox(value: d.inHours % 24, label: 'Hrs'),
              const SizedBox(width: 6),
              _CounterBox(value: d.inMinutes % 60, label: 'Min'),
              const SizedBox(width: 6),
              _CounterBox(value: d.inSeconds % 60, label: 'Seg'),
              const SizedBox(width: 10),
              const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'juntos',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    'desde',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
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

class _CounterBox extends StatelessWidget {
  final int value;
  final String label;
  const _CounterBox({required this.value, required this.label});

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
