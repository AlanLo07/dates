import 'package:flutter/material.dart';
import '../models/weekly_question.dart';
import '../services/weekly_questions_service.dart';
import '../widgets/weekly_question_card.dart';
import 'package:intl/intl.dart';

class WeeklyQuestionsHistoryScreen extends StatefulWidget {
  final Function(WeeklyQuestion) onQuestionTap;

  const WeeklyQuestionsHistoryScreen({
    super.key,
    required this.onQuestionTap,
  });

  @override
  State<WeeklyQuestionsHistoryScreen> createState() =>
      _WeeklyQuestionsHistoryScreenState();
}

class _WeeklyQuestionsHistoryScreenState
    extends State<WeeklyQuestionsHistoryScreen> {
  late WeeklyQuestionsService _service;
  List<WeeklyQuestion> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _nextToken;
  bool _hasMore = true;
  late ScrollController _scrollController;
  String _filterStatus = 'completed';
  final List<String> _statusOptions = [
    'completed',
    'partial',
    'pending',
    'unseen',
  ];

  @override
  void initState() {
    super.initState();
    _service = WeeklyQuestionsService.instance;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadQuestions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasMore &&
        !_isLoading) {
      _loadMore();
    }
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _questions.clear();
        _nextToken = null;
      });

      final response = await _service.getQuestions(
        status: _filterStatus,
      );

      setState(() {
        _questions = response.items;
        _nextToken = response.nextToken;
        _hasMore = response.nextToken != null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _loadMore() async {
    if (_nextToken == null) return;

    try {
      final response = await _service.getQuestions(
        status: _filterStatus,
        nextToken: _nextToken,
      );

      setState(() {
        _questions.addAll(response.items);
        _nextToken = response.nextToken;
        _hasMore = response.nextToken != null;
      });
    } catch (e) {
      debugPrint('Error loading more: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtro de estado
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: _statusOptions.map((status) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(_getStatusLabel(status)),
                  selected: _filterStatus == status,
                  onSelected: (_) {
                    setState(() => _filterStatus = status);
                    _loadQuestions();
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Lista de preguntas
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading && _questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_errorMessage ?? 'Error'),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getEmptyIcon(),
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _getEmptyTitle(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _getEmptyMessage(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _questions.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _questions.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          );
        }

        final question = _questions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => widget.onQuestionTap(question),
            child: WeeklyQuestionCard(question: question),
          ),
        );
      },
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return '✅ Completadas';
      case 'partial':
        return '⏳ Una respuesta';
      case 'pending':
        return '📝 Sin respuestas';
      case 'unseen':
        return '👁️ Nueva';
      default:
        return status;
    }
  }

  IconData _getEmptyIcon() {
    switch (_filterStatus) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'partial':
        return Icons.hourglass_empty;
      case 'pending':
        return Icons.pending_actions;
      case 'unseen':
        return Icons.visibility_off;
      default:
        return Icons.inbox_outlined;
    }
  }

  String _getEmptyTitle() {
    switch (_filterStatus) {
      case 'completed':
        return 'Sin preguntas completadas';
      case 'partial':
        return 'Sin preguntas parciales';
      case 'pending':
        return 'Sin preguntas pendientes';
      case 'unseen':
        return 'Sin preguntas nuevas';
      default:
        return 'Sin preguntas';
    }
  }

  String _getEmptyMessage() {
    switch (_filterStatus) {
      case 'completed':
        return 'Las preguntas que completes juntos aparecerán aquí';
      case 'partial':
        return 'Las preguntas con una respuesta aparecerán aquí';
      case 'pending':
        return 'Las preguntas sin respuestas aparecerán aquí';
      case 'unseen':
        return 'Las preguntas nuevas aparecerán aquí';
      default:
        return 'No hay preguntas disponibles';
    }
  }
}
