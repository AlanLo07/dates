// lib/screens/letters.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/carta.dart';
import '../utils/colors.dart';

class LetterScreen extends StatefulWidget {
  final CartaSorpresa carta;
  const LetterScreen({super.key, required this.carta});

  @override
  State<LetterScreen> createState() => _LetterScreenState();
}

class _LetterScreenState extends State<LetterScreen>
    with TickerProviderStateMixin {
  bool _isOpened = false;

  // ── Animación del sobre (flip 3D) ─────────────────────────────────────────
  late final AnimationController _flipController;
  late final Animation<double> _flipAngle;

  // ── Animación de aparición del contenido ──────────────────────────────────
  late final AnimationController _contentController;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;

  // ── Partículas de confeti ─────────────────────────────────────────────────
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAngle = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
        );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _contentController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_isOpened) return;
    setState(() => _isOpened = true);
    await _flipController.forward();
    _particleController.forward();
    await _contentController.forward();
  }

  Future<void> _close() async {
    if (!_isOpened) return;
    await _contentController.reverse();
    await _flipController.reverse();
    if (mounted) setState(() => _isOpened = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.letterBg,
      appBar: AppBar(
        backgroundColor: AppColors.letterBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.violeta),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.carta.title,
          style: const TextStyle(
            color: AppColors.violeta,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          // ── Fondo decorativo ─────────────────────────────────────────────
          Positioned.fill(child: _buildBackground()),

          // ── Contenido central ─────────────────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: _isOpened ? _close : _open,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isOpened ? _buildOpenCard() : _buildEnvelope(),
              ),
            ),
          ),

          // ── Hint de acción ───────────────────────────────────────────────
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _isOpened ? 'Toca para cerrar' : 'Toca para abrir 💌',
                  style: TextStyle(
                    color: AppColors.violeta.withOpacity(0.5),
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fondo con corazones decorativos ───────────────────────────────────────
  Widget _buildBackground() {
    return CustomPaint(painter: _HeartPatternPainter());
  }

  // ── Sobre cerrado ─────────────────────────────────────────────────────────
  Widget _buildEnvelope() {
    return AnimatedBuilder(
      animation: _flipController,
      builder: (ctx, child) {
        // Sólo mostramos el frente (ángulo < π/2)
        final angle = _flipAngle.value;
        if (angle > math.pi / 2) return const SizedBox.shrink();
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: child,
        );
      },
      child: Container(
        key: const ValueKey('envelope'),
        width: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flap del sobre
            ClipPath(
              clipper: _EnvelopeFlapClipper(),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
            ),
            // Cuerpo del sobre
            Container(
              height: 140,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    size: 48,
                    color: Colors.pinkAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.carta.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.violeta,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Carta abierta ─────────────────────────────────────────────────────────
  Widget _buildOpenCard() {
    return FadeTransition(
      opacity: _contentOpacity,
      child: SlideTransition(
        position: _contentSlide,
        child: Container(
          key: const ValueKey('content'),
          width: 320,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera rosada
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.pink.shade50,
                      Colors.pink.shade100.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('💌', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.carta.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.violeta,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Separador decorativo
              Container(
                height: 2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.pinkAccent,
                      AppColors.malva,
                      AppColors.celeste,
                    ],
                  ),
                ),
              ),
              // Cuerpo del mensaje
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    widget.carta.description,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: Color(0xFF444444),
                    ),
                  ),
                ),
              ),
              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.carta.date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
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

// ── Clip para el flap del sobre ───────────────────────────────────────────────
class _EnvelopeFlapClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.4);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height * 0.4);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_EnvelopeFlapClipper old) => false;
}

// ── Fondo con corazones decorativos ──────────────────────────────────────────
class _HeartPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pink.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    const emojis = ['♥', '✿', '❀', '♡'];
    final textStyle = TextStyle(
      fontSize: 24,
      color: Colors.pinkAccent.withOpacity(0.08),
    );

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 5; col++) {
        final x = col * (size.width / 4) + (row.isOdd ? 30.0 : 0.0);
        final y = row * 90.0 - 20;
        final emoji = emojis[(row + col) % emojis.length];
        final span = TextSpan(text: emoji, style: textStyle);
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
          ..layout();
        tp.paint(canvas, Offset(x, y));
      }
    }
    // ignorar lint: no tenemos uso de paint en este painter
    canvas.drawRect(Rect.zero, paint);
  }

  @override
  bool shouldRepaint(_HeartPatternPainter old) => false;
}
