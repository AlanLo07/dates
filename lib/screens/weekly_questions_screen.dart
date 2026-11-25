import 'package:flutter/material.dart';
import '../models/weekly_question.dart';
import '../services/weekly_questions_service.dart';
import '../services/auth_service.dart';
import 'weekly_questions_detail_screen.dart';
import 'weekly_questions_create_screen.dart';
import 'weekly_questions_answer_screen.dart';
import 'weekly_questions_catalog_screen.dart';
import 'weekly_questions_history_screen.dart';
import '../widgets/weekly_question_card.dart';
import 'package:intl/intl.dart';

class WeeklyQuestionsScreen extends StatefulWidget {
  const WeeklyQuestionsScreen({super.key});

  @override
  State<WeeklyQuestionsScreen> createState() => _WeeklyQuestionsScreenState();
}

class _WeeklyQuestionsScreenState extends State<WeeklyQuestionsScreen>
    with WidgetsBindingObserver {
  late WeeklyQuestionsService _service;
  late AuthService _authService;
  late WeeklyQuestionsResponse _currentWeekResponse;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _service = WeeklyQuestionsService.instance;
    _authService = AuthService.instance;
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentQuestion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Se ejecuta cuando la app recupera foco
  /// Recarga la pregunta actual por si cambió
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      _loadCurrentQuestion();
    }
  }

  Future<void> _loadCurrentQuestion() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _service.getCurrentQuestion();

      if (mounted) {
        setState(() {
          _currentWeekResponse = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
      debugPrint('Error loading current question: $e');
    }
  }

  Future<void> _refreshQuestion() async {
    await _loadCurrentQuestion();
  }

  String _getPartnerSub() {
    final currentUserSub = _authService.user?.sub;
    final users = _currentWeekResponse.users;
    for (final user in users) {
      if (user.sub != currentUserSub) {
        return user.sub;
      }
    }
    return '';
  }

  String _getPartnerName() {
    final currentUserSub = _authService.user?.sub;
    final users = _currentWeekResponse.users;
    for (final user in users) {
      if (user.sub != currentUserSub) {
        return user.name.isNotEmpty ? user.name : 'Tu pareja';
      }
    }
    return 'Tu pareja';
  }

  Future<void> _handleAnswerSubmitted() async {
    // Después de enviar una respuesta, refrescar la pregunta
    await _loadCurrentQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pregunta de la Semana'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _isLoading ? null : _refreshQuestion,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildMainView(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error al cargar',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Algo salió mal',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: _refreshQuestion,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainView() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Actual'),
              Tab(text: 'Catálogo'),
              Tab(text: 'Historial'),
            ],
            onTap: (index) {
              setState(() => _selectedTabIndex = index);
            },
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCurrentTab(),
                _buildCatalogTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    final question = _currentWeekResponse.question;

    if (question == null) {
      return _buildEmptyState();
    }

    final partnerSub = _getPartnerSub();
    final partnerName = _getPartnerName();
    final currentUserAnswer = question.answers[_authService.user?.sub];
    final partnerAnswer = question.answers[partnerSub];

    return RefreshIndicator(
      onRefresh: _refreshQuestion,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de semana
            _buildWeekHeader(),
            const SizedBox(height: 24),

            // Tarjeta de pregunta
            WeeklyQuestionCard(
              question: question,
              onTap: () => _navigateToDetail(question),
            ),
            const SizedBox(height: 24),

            // Respuesta propia
            if (question.canAnswer || question.canEdit)
              _buildMyAnswerSection(question, currentUserAnswer),

            if (question.canAnswer || currentUserAnswer != null)
              const SizedBox(height: 24),

            // Respuesta de la pareja
            _buildPartnerAnswerSection(
              partnerName,
              partnerAnswer,
              question.status == 'pending' || question.status == 'partial',
            ),

            const SizedBox(height: 24),

            // Información de categoría y estado
            _buildQuestionInfo(question),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshQuestion,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.question_answer_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  'No hay preguntas disponibles',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Cuando agregues preguntas al catálogo, aparecerán aquí cada semana.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Crear primera pregunta'),
                  onPressed: () => _navigateToCreateQuestion(),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekHeader() {
    final formatter = DateFormat('d MMMM', 'es_ES');
    final weekEnd = _currentWeekResponse.weekEnd.subtract(
      const Duration(days: 1),
    );
    final weekRange =
        '${formatter.format(_currentWeekResponse.weekStart)} - ${formatter.format(weekEnd)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Semana del $weekRange',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMyAnswerSection(WeeklyQuestion question, Answer? currentAnswer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu respuesta',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (currentAnswer != null)
          _buildAnswerCard(currentAnswer, isYours: true)
        else
          GestureDetector(
            onTap: question.canAnswer
                ? () => _navigateToAnswerQuestion(question)
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.edit, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Escribe tu respuesta',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPartnerAnswerSection(
    String partnerName,
    Answer? partnerAnswer,
    bool isPending,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Respuesta de $partnerName',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (partnerAnswer != null)
          _buildAnswerCard(partnerAnswer, isYours: false)
        else if (isPending)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.amber[300]!,
                style: BorderStyle.solid,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.amber[50],
            ),
            child: Column(
              children: [
                Icon(Icons.hourglass_empty, color: Colors.amber[700]),
                const SizedBox(height: 8),
                Text(
                  '$partnerName aún no responde',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.amber[900]),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Sin respuesta',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnswerCard(Answer answer, {required bool isYours}) {
    return GestureDetector(
      onTap: isYours
          ? () {
              final question = _currentWeekResponse.question;
              if (question != null && question.canEdit) {
                _navigateToAnswerQuestion(question);
              }
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isYours ? Colors.pink[50] : Colors.blue[50],
          border: Border.all(
            color: isYours ? Colors.pink[300]! : Colors.blue[300]!,
            style: BorderStyle.solid,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(answer.text, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  DateFormat('d/MM/y H:mm', 'es_ES').format(answer.updatedAt),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                ),
                if (answer.isEdited())
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      '(editada)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.amber[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInfo(WeeklyQuestion question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.label_outline, size: 16),
              const SizedBox(width: 8),
              Text(
                question.category,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16),
              const SizedBox(width: 8),
              Text(
                'Estado: ${_getStatusText(question.status)}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'unseen':
        return 'No presentada';
      case 'pending':
        return 'Pendiente de respuestas';
      case 'partial':
        return 'Una respuesta pendiente';
      case 'completed':
        return 'Completada';
      default:
        return status;
    }
  }

  Widget _buildCatalogTab() {
    return WeeklyQuestionsCatalogScreen(
      onCreatePressed: () => _navigateToCreateQuestion(),
    );
  }

  Widget _buildHistoryTab() {
    return WeeklyQuestionsHistoryScreen(
      onQuestionTap: (question) => _navigateToDetail(question),
    );
  }

  void _navigateToCreateQuestion() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => const WeeklyQuestionsCreateScreen(),
          ),
        )
        .then((_) {
          // Refrescar el catálogo después de crear una pregunta
          _loadCurrentQuestion();
        });
  }

  void _navigateToAnswerQuestion(WeeklyQuestion question) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => WeeklyQuestionsAnswerScreen(
              question: question,
              onAnswerSubmitted: _handleAnswerSubmitted,
            ),
          ),
        )
        .then((_) {
          // Refrescar después de responder
          _loadCurrentQuestion();
        });
  }

  void _navigateToDetail(WeeklyQuestion question) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeeklyQuestionsDetailScreen(question: question),
      ),
    );
  }

  Widget? _buildFAB() {
    if (_isLoading || _errorMessage != null) return null;

    if (_selectedTabIndex == 0) {
      // Pestaña "Actual" - mostrar FAB para responder si es necesario
      final question = _currentWeekResponse.question;
      if (question != null && question.canAnswer) {
        return FloatingActionButton(
          onPressed: () => _navigateToAnswerQuestion(question),
          tooltip: 'Responder pregunta',
          child: const Icon(Icons.edit),
        );
      }
    } else if (_selectedTabIndex == 1) {
      // Pestaña "Catálogo" - mostrar FAB para crear pregunta
      return FloatingActionButton(
        onPressed: _navigateToCreateQuestion,
        tooltip: 'Crear pregunta',
        child: const Icon(Icons.add),
      );
    }
    return null;
  }
}
