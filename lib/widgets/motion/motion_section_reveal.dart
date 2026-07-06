import 'package:flutter/material.dart';

import '../../utils/animations.dart';

class MotionSectionReveal extends StatefulWidget {
  final Widget child;
  final Duration? delay;
  final double beginOffsetY;

  const MotionSectionReveal({
    super.key,
    required this.child,
    this.delay,
    this.beginOffsetY = 0.06,
  });

  @override
  State<MotionSectionReveal> createState() => _MotionSectionRevealState();
}

class _MotionSectionRevealState extends State<MotionSectionReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionDurations.medium,
    );

    _fade = CurvedAnimation(parent: _controller, curve: MotionCurves.entrance);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.beginOffsetY),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: MotionCurves.entrance));

    final delay = widget.delay ?? Duration.zero;
    Future<void>.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
