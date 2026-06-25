import 'dart:math' as math;

import 'package:flutter/material.dart';

class OwlHelperWidget extends StatefulWidget {
  final String message;
  final bool celebrate;
  final bool warning;

  const OwlHelperWidget({
    super.key,
    required this.message,
    this.celebrate = false,
    this.warning = false,
  });

  @override
  State<OwlHelperWidget> createState() => _OwlHelperWidgetState();
}

class _OwlHelperWidgetState extends State<OwlHelperWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_controller.value);
        final floatY = math.sin(t * math.pi * 2) * 3;
        final wing = 0.25 + (t * 0.75);

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Row(
            children: [
              CustomPaint(
                size: const Size(92, 92),
                painter: _OwlPainter(
                  wingProgress: wing,
                  celebrate: widget.celebrate,
                  warning: widget.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF796B9B).withOpacity(0.14),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Color(0xFF796B9B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OwlPainter extends CustomPainter {
  final double wingProgress;
  final bool celebrate;
  final bool warning;

  _OwlPainter({
    required this.wingProgress,
    required this.celebrate,
    required this.warning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.48, size.height * 0.54);

    final body = Paint()..color = const Color(0xFF8D7AAE);
    final belly = Paint()..color = const Color(0xFFDCCEEF);
    final wing = Paint()
      ..color = warning ? const Color(0xFFE57373) : const Color(0xFF6E5D8A);
    final eyeWhite = Paint()..color = Colors.white;
    final pupil = Paint()..color = const Color(0xFF2F2740);
    final beak = Paint()..color = const Color(0xFFF8B84E);

    canvas.drawOval(
      Rect.fromCenter(center: center, width: 58, height: 68),
      body,
    );

    final wingLift = (wingProgress - 0.5) * 10;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - 26, center.dy + 6 - wingLift),
        width: 24,
        height: 34,
      ),
      wing,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + 26, center.dy + 6 - wingLift),
        width: 24,
        height: 34,
      ),
      wing,
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 8), width: 34, height: 40),
      belly,
    );

    canvas.drawCircle(Offset(center.dx - 12, center.dy - 12), 10, eyeWhite);
    canvas.drawCircle(Offset(center.dx + 12, center.dy - 12), 10, eyeWhite);
    canvas.drawCircle(Offset(center.dx - 12, center.dy - 12), 4, pupil);
    canvas.drawCircle(Offset(center.dx + 12, center.dy - 12), 4, pupil);

    final beakPath = Path()
      ..moveTo(center.dx, center.dy - 1)
      ..lineTo(center.dx - 6, center.dy + 7)
      ..lineTo(center.dx + 6, center.dy + 7)
      ..close();
    canvas.drawPath(beakPath, beak);

    if (celebrate) {
      final confetti = Paint()..color = const Color(0xFF81C784);
      canvas.drawCircle(Offset(center.dx - 22, center.dy - 32), 3.2, confetti);
      canvas.drawCircle(Offset(center.dx + 24, center.dy - 28), 3.2, confetti);
      canvas.drawCircle(Offset(center.dx + 6, center.dy - 38), 3.2, confetti);
    }
  }

  @override
  bool shouldRepaint(covariant _OwlPainter oldDelegate) {
    return oldDelegate.wingProgress != wingProgress ||
        oldDelegate.celebrate != celebrate ||
        oldDelegate.warning != warning;
  }
}