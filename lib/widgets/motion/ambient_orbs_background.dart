import 'dart:math' as math;

import 'package:flutter/material.dart';

class AmbientOrbsBackground extends StatefulWidget {
  final List<Color> colors;
  final Widget child;

  const AmbientOrbsBackground({
    super.key,
    required this.colors,
    required this.child,
  });

  @override
  State<AmbientOrbsBackground> createState() => _AmbientOrbsBackgroundState();
}

class _AmbientOrbsBackgroundState extends State<AmbientOrbsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
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
      builder: (context, _) {
        final t = _controller.value;
        final dxA = math.sin(t * math.pi * 2) * 26;
        final dyA = math.cos(t * math.pi * 2) * 20;
        final dxB = math.cos((t + 0.18) * math.pi * 2) * 20;
        final dyB = math.sin((t + 0.18) * math.pi * 2) * 26;

        return Stack(
          children: [
            Positioned.fill(child: widget.child),
            Positioned(
              top: -30 + dyA,
              left: -20 + dxA,
              child: _Orb(color: widget.colors[0], size: 190),
            ),
            Positioned(
              bottom: -35 + dyB,
              right: -24 + dxB,
              child: _Orb(color: widget.colors[1 % widget.colors.length], size: 220),
            ),
            Positioned(
              top: 180 + dyB,
              right: 42 + dxA * 0.4,
              child: _Orb(color: widget.colors[2 % widget.colors.length], size: 120),
            ),
          ],
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;

  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.18),
              color.withOpacity(0.03),
            ],
          ),
        ),
      ),
    );
  }
}
