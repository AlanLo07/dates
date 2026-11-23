import 'package:flutter/material.dart';
import '../../../models/weekly_question.dart';
import '../../../services/weekly_questions_service.dart';
import '../../../utils/animations.dart';
import '../../../widgets/motion/motion_pressable.dart';
import '../../weekly_questions_screen.dart';
import 'home_animated_entry_card.dart';

class HomeWeeklyQuestionsCard extends StatefulWidget {
  final int index;
  final Duration fadeDuration;
  final Duration slideDuration;
  final Duration stagger;

  const HomeWeeklyQuestionsCard({
    super.key,
    required this.index,
    required this.fadeDuration,
    required this.slideDuration,
    required this.stagger,
  });

  @override
  State<HomeWeeklyQuestionsCard> createState() =>
      _HomeWeeklyQuestionsCardState();
}

class _HomeWeeklyQuestionsCardState extends State<HomeWeeklyQuestionsCard> {
  late WeeklyQuestionsService _service;
  WeeklyQuestionsResponse? _response;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = WeeklyQuestionsService.instance;
    _loadCurrentQuestion();
  }

  Future<void> _loadCurrentQuestion() async {
    try {
      final response = await _service.getCurrentQuestion();
      if (mounted) {
        setState(() {
          _response = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
      debugPrint('Error loading current question for card: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeAnimatedEntryCard(
      index: widget.index,
      fadeDuration: widget.fadeDuration,
      slideDuration: widget.slideDuration,
      stagger: widget.stagger,
      child: MotionPressable(
        pressedScale: 0.98,
        borderRadius: BorderRadius.circular(20),
        onTap: () => _navigateToFullScreen(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF9C8DC4),
                Color(0xFF6B5B95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B5B95).withValues(alpha: 0.30),
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
                  '❓',
                  style: TextStyle(
                    fontSize: 64,
                    color: Colors.white.withValues(alpha: 0.18),
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
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.quiz_rounded,
                        color: Colors.white,
                        size: 26,
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
                            'Pregunta de la Semana',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          _buildSubtitleText(),
                        ],
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

  Widget _buildSubtitleText() {
    if (_isLoading) {
      return const Text(
        'Cargando...',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (_errorMessage != null) {
      return const Text(
        'Error al cargar',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final question = _response?.question;

    if (question == null) {
      return const Text(
        'No hay preguntas disponibles',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final statusText = _getStatusEmoji(question) + ' ' + _getStatusText(question);

    return Text(
      statusText,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getStatusEmoji(WeeklyQuestion question) {
    switch (question.status) {
      case 'completed':
        return '✅';
      case 'partial':
        return '⏳';
      case 'pending':
        return '📝';
      default:
        return '❓';
    }
  }

  String _getStatusText(WeeklyQuestion question) {
    switch (question.status) {
      case 'completed':
        return 'Completada';
      case 'partial':
        return 'Una respuesta pendiente';
      case 'pending':
        return 'Pendiente de respuestas';
      default:
        return question.category;
    }
  }

  void _navigateToFullScreen(BuildContext context) {
    Navigator.of(context).push(
      createRoute(const WeeklyQuestionsScreen(), motion: AppRouteMotion.sharedAxisX),
    );
  }
}
