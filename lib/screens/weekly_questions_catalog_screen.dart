import 'package:flutter/material.dart';
import '../models/weekly_question.dart';
import '../services/weekly_questions_service.dart';
import '../widgets/weekly_question_card.dart';

class WeeklyQuestionsCatalogScreen extends StatefulWidget {
  final VoidCallback onCreatePressed;

  const WeeklyQuestionsCatalogScreen({
    super.key,
    required this.onCreatePressed,
  });

  @override
  State<WeeklyQuestionsCatalogScreen> createState() =>
      _WeeklyQuestionsCatalogScreenState();
}

class _WeeklyQuestionsCatalogScreenState
    extends State<WeeklyQuestionsCatalogScreen> {
  late WeeklyQuestionsService _service;
  List<CatalogQuestion> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _nextToken;
  bool _hasMore = true;
  late ScrollController _scrollController;
  String? _selectedCategory;
  final List<String> _categories = [
    'divertidas',
    'profundas',
    'romanticas',
    'absurdas',
    'otras',
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

      final response = await _service.getCatalog(
        category: _selectedCategory,
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
      debugPrint('Error loading catalog: $e');
    }
  }

  Future<void> _loadMore() async {
    if (_nextToken == null) return;

    try {
      final response = await _service.getCatalog(
        category: _selectedCategory,
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
        // Filtro de categorías
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: const Text('Todas'),
                  selected: _selectedCategory == null,
                  onSelected: (_) {
                    setState(() => _selectedCategory = null);
                    _loadQuestions();
                  },
                ),
              ),
              ..._categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                      _loadQuestions();
                    },
                  ),
                );
              }),
            ],
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Error al cargar',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Algo salió mal',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Sin preguntas',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Crea la primera pregunta del catálogo',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Crear Pregunta'),
                onPressed: widget.onCreatePressed,
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
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildCatalogQuestionCard(question),
        );
      },
    );
  }

  Widget _buildCatalogQuestionCard(CatalogQuestion question) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(question.category),
            ),
            const SizedBox(height: 12),
            Text(
              question.text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'v${question.version}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const Spacer(),
                Text(
                  'Creada por: ${question.createdBy.substring(0, 8)}...',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
