import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/animations.dart';

class MotionPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool useHaptics;
  final double pressedScale;

  const MotionPressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.useHaptics = true,
    this.pressedScale = 0.97,
  });

  @override
  State<MotionPressable> createState() => _MotionPressableState();
}

class _MotionPressableState extends State<MotionPressable> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _triggerTap() {
    if (widget.onTap == null) return;
    if (widget.useHaptics) {
      HapticFeedback.selectionClick();
    }
    widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    final shadowScale = _isPressed
        ? 0.65
        : _isHovered
        ? 1.15
        : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _isPressed = false),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _isPressed = false),
      onTap: _triggerTap,
      child: MouseRegion(
        cursor: widget.onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          duration: MotionDurations.micro,
          curve: MotionCurves.emphasized,
          scale: _isPressed ? widget.pressedScale : 1,
          child: AnimatedContainer(
            duration: MotionDurations.short,
            curve: MotionCurves.entrance,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05 * shadowScale),
                  blurRadius: 12 * shadowScale,
                  offset: Offset(0, 4 * shadowScale),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
