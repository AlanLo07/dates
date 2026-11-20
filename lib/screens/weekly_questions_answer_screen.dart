import 'package:flutter/material.dart';
import '../models/weekly_question.dart';
import '../services/weekly_questions_service.dart';

class WeeklyQuestionsAnswerScreen extends StatefulWidget {
  final WeeklyQuestion question;
  final Future<void> Function() onAnswerSubmitted;

  const WeeklyQuestionsAnswerScreen({
    super.key,
    required this.question,
    required this.onAnswerSubmitted,
  });

  @override
  State<WeeklyQuestionsAnswerScreen> createState() =>
      _WeeklyQuestionsAnswerScreenState();
}

class _WeeklyQuestionsAnswerScreenState
    extends State<WeeklyQuestionsAnswerScreen> {
  late WeeklyQuestionsService _service;
  late TextEditingController _answerController;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _service = WeeklyQuestionsService.instance;
    _answerController = TextEditingController();

    // Si ya existe una respuesta, cargarla
    final currentUserAnswer = widget.question.answers.values.isNotEmpty
        ? widget.question.answers.values.first
        : null;

    if (currentUserAnswer != null) {
      _answerController.text = currentUserAnswer.text;
      _isEditing = true;
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    final text = _answerController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La respuesta no puede estar vacía'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _service.submitAnswer(
        questionId: widget.question.id,
        text: text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? '¡Respuesta actualizada!'
                : '¡Respuesta guardada!'),
            duration: const Duration(seconds: 2),
          ),
        );

        // Esperar a que se notifique la actualización
        await widget.onAnswerSubmitted();

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
      debugPrint('Error submitting answer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Respuesta' : 'Responder Pregunta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pregunta
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(widget.question.category),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.question.text,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Campo de respuesta
            Text(
              _isEditing ? 'Tu respuesta actual' : 'Tu respuesta',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              minLines: 5,
              maxLines: 10,
              maxLength: 5000,
              decoration: InputDecoration(
                hintText: 'Escribe tu respuesta aquí...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: 'Entre 1 y 5000 caracteres',
              ),
            ),

            // Mensaje de error
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red[700],
                      ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Botones
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAnswer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Actualizar Respuesta' : 'Guardar Respuesta'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Cancelar'),
                ),
              ),
            ),

            if (_isEditing) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  border: Border.all(color: Colors.amber[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Puedes editar tu respuesta en cualquier momento.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.amber[900],
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
