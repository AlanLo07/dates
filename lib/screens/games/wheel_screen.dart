// lib/screens/games/wheel_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import '../../data/desire_content.dart';
import '../../utils/colors.dart';

const List<Color> _wheelColors = [
  Color(0xFF796B9B),
  Color(0xFFB0B6E8),
  Color(0xFFA9D1DF),
  Color(0xFFF48FB1),
  Color(0xFFCE6D8B),
  Color(0xFFE57373),
  Color(0xFFFFB74D),
  Color(0xFF9575CD),
];

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen>
    with SingleTickerProviderStateMixin {
  DesireLevel? _filterLevel;
  final _random = Random();

  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  late ConfettiController _confetti;

  double _currentAngle = 0.0;
  double _targetAngle = 0.0;
  ChallengeItem? _result;
  bool _isSpinning = false;
  bool _showResult = false;

  List<ChallengeItem> get _pool {
    if (_filterLevel == null) return kChallenges;
    final f = kChallenges.where((c) => c.level == _filterLevel).toList();
    return f.isEmpty ? kChallenges : f;
  }

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    )..addListener(() {
        setState(() => _currentAngle = _spinAnimation.value * _targetAngle);
      });
    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
          _showResult = true;
        });
        HapticFeedback.heavyImpact();
        _confetti.play();
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;
    HapticFeedback.mediumImpact();

    final items = _pool;
    final winner = _random.nextInt(items.length);
    final sliceAngle = (2 * pi) / items.length;

    final extraSpins = (5 + _random.nextInt(3)) * 2 * pi;
    final winnerCenter = winner * sliceAngle + sliceAngle / 2 - pi / 2;
    final alignAngle = (3 * pi / 2 - winnerCenter) % (2 * pi);
    _targetAngle =
        _currentAngle + extraSpins + alignAngle - (_currentAngle % (2 * pi));

    setState(() {
      _isSpinning = true;
      _showResult = false;
      _result = null;
    });

    _spinController.reset();
    _spinController.forward();

    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) setState(() => _result = items[winner]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _pool;
    final sliceAngle = (2 * pi) / items.length;

    return Scaffold(
      backgroundColor: AppColors.lavanda,
      appBar: AppBar(
        title: const Text(
          '🎡 Ruleta de Retos',
          style: TextStyle(color: AppColors.violeta, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.violeta),
        elevation: 1,
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildLevelFilter(),
                const SizedBox(height: 8),

                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPointer(),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 300,
                          height: 300,
                          child: Transform.rotate(
                            angle: _currentAngle,
                            child: CustomPaint(
                              painter: _ChallengeWheelPainter(
                                items: items,
                                colors: _wheelColors,
                                sliceAngle: sliceAngle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _showResult && _result != null
                      ? _buildResultCard(_result!)
                      : const SizedBox(height: 20),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: GestureDetector(
                    onTap: _isSpinning ? null : _spin,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: _isSpinning
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFFB0B6E8), Color(0xFF796B9B)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                        color: _isSpinning ? Colors.grey.shade300 : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isSpinning
                            ? []
                            : [
                                BoxShadow(
                                  color: AppColors.violeta.withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Center(
                        child: _isSpinning
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.violeta,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Girando...',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🎡', style: TextStyle(fontSize: 20)),
                                  SizedBox(width: 10),
                                  Text(
                                    '¡GIRAR LA RULETA!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 24,
            colors: const [
              Color(0xFFF48FB1),
              Color(0xFFB0B6E8),
              Color(0xFFA9D1DF),
              Colors.white,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _levelChip(null, 'Todos', '🎡'),
          const SizedBox(width: 8),
          for (final l in DesireLevel.values) ...[
            _levelChip(l, l.label, l.emoji),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _levelChip(DesireLevel? level, String label, String emoji) {
    final isSelected = _filterLevel == level;
    final color = level?.color ?? AppColors.violeta;
    return GestureDetector(
      onTap: _isSpinning ? null : () => setState(() => _filterLevel = level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointer() {
    return CustomPaint(size: const Size(24, 20), painter: _PointerPainter());
  }

  Widget _buildResultCard(ChallengeItem item) {
    return Container(
      key: ValueKey(item.text),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: item.level.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item.level.color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: item.level.color.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            '${item.level.emoji} Reto ${item.level.label}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: item.level.color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.violeta,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painter de la ruleta con emojis ─────────────────────────────────────────
class _ChallengeWheelPainter extends CustomPainter {
  final List<ChallengeItem> items;
  final List<Color> colors;
  final double sliceAngle;

  _ChallengeWheelPainter({
    required this.items,
    required this.colors,
    required this.sliceAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 2;

    for (int i = 0; i < items.length; i++) {
      final startAngle = i * sliceAngle - pi / 2;
      final color = colors[i % colors.length];

      paint.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        paint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        borderPaint,
      );

      final textAngle = startAngle + sliceAngle / 2;
      final textRadius = radius * 0.68;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: items[i].emoji,
          style: const TextStyle(fontSize: 22),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }

    paint.color = Colors.white;
    canvas.drawCircle(center, 18, paint);
    paint.color = AppColors.violeta;
    canvas.drawCircle(center, 14, paint);
  }

  @override
  bool shouldRepaint(_ChallengeWheelPainter old) => false;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.violeta
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => false;
}