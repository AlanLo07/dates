import 'package:flutter/material.dart';

import '../../../utils/colors.dart';

class HomeCounterStrip extends StatelessWidget {
  final Stream<Duration> stream;
  final Duration initial;

  const HomeCounterStrip({
    super.key,
    required this.stream,
    required this.initial,
  });

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
              _HomeCounterBox(value: d.inDays, label: 'Días'),
              const SizedBox(width: 6),
              _HomeCounterBox(value: d.inHours % 24, label: 'Hrs'),
              const SizedBox(width: 6),
              _HomeCounterBox(value: d.inMinutes % 60, label: 'Min'),
              const SizedBox(width: 6),
              _HomeCounterBox(value: d.inSeconds % 60, label: 'Seg'),
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

class _HomeCounterBox extends StatefulWidget {
  final int value;
  final String label;

  const _HomeCounterBox({required this.value, required this.label});

  @override
  State<_HomeCounterBox> createState() => _HomeCounterBoxState();
}

class _HomeCounterBoxState extends State<_HomeCounterBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  int _lastValue = 0;
  bool _isFlipping = false;

  @override
  void initState() {
    super.initState();
    _lastValue = widget.value;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_HomeCounterBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isFlipping) {
      _isFlipping = true;
      _controller.forward(from: 0).then((_) {
        _lastValue = widget.value;
        _isFlipping = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          SizedBox(
            height: 30,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.92,
                      end: 1.0,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                widget.value.toString().padLeft(2, '0'),
                key: ValueKey<int>(widget.value),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.violeta,
                ),
              ),
            ),
          ),
          Text(
            widget.label,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
