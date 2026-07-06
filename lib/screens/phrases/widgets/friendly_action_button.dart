import 'package:flutter/material.dart';

import '../../../utils/animations.dart';
import '../../../widgets/motion/motion_pressable.dart';

class FriendlyActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const FriendlyActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    this.foregroundColor = Colors.white,
  });

  @override
  State<FriendlyActionButton> createState() => _FriendlyActionButtonState();
}

class _FriendlyActionButtonState extends State<FriendlyActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MotionPressable(
      onTap: widget.onPressed,
      pressedScale: 0.96,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedScale(
        duration: MotionDurations.micro,
        scale: _isPressed ? 0.98 : 1,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapCancel: () => setState(() => _isPressed = false),
          onTapUp: (_) => setState(() => _isPressed = false),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(widget.backgroundColor, Colors.white, 0.10) ??
                      widget.backgroundColor,
                  widget.backgroundColor,
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 20, color: widget.foregroundColor),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.foregroundColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}