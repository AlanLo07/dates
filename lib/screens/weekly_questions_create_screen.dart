import 'package:flutter/material.dart';
import '../models/weekly_question.dart';
import '../services/weekly_questions_service.dart';

class WeeklyQuestionsCreateScreen extends StatefulWidget {
  const WeeklyQuestionsCreateScreen({super.key});

  @override
  State<WeeklyQuestionsCreateScreen> createState() =>
      _WeeklyQuestionsCreateScreenState();
}

class _WeeklyQuestionsCreateScreenState
    extends State<WeeklyQuestionsCreateScreen> {
  late WeeklyQuestionsService _service;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;
  late TextEditingController _categoryController;
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _suggestedCategories = [
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
    _textController = TextEditingController();
    _categoryController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final question = await _service.createCatalogQuestion(
        text: _textController.text,
        category: _categoryController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pregunta creada exitosamente!'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(question);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
      debugPrint('Error creating question: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Pregunta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nueva Pregunta',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ambos integrantes pueden crear y editar preguntas del catálogo. Cada semana se selecciona una al azar para responder.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Formulario
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texto de la pregunta
                  TextFormField(
                    controller: _textController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      labelText: 'Pregunta',
                      hintText: 'Escribe una pregunta interesante...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: 'Entre 1 y 1000 caracteres',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La pregunta no puede estar vacía';
                      }
                      if (value.trim().length < 1 || value.trim().length > 1000) {
                        return 'La pregunta debe tener entre 1 y 1000 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Categoría
                  Text(
                    'Categoría',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _categoryController,
                    maxLength: 60,
                    decoration: InputDecoration(
                      hintText: 'Ej: divertidas, profundas, romanticas...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: 'Sugerencias: divertidas, profundas, romanticas, absurdas, otras',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Selecciona una categoría';
                      }
                      if (value.trim().length < 1 || value.trim().length > 60) {
                        return 'La categoría debe tener entre 1 y 60 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Sugerencias de categorías
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestedCategories.map((category) {
                      return ActionChip(
                        label: Text(category),
                        onPressed: () {
                          _categoryController.text = category;
                        },
                      );
                    }).toList(),
                  ),
                ],
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
                onPressed: _isSubmitting ? null : _submitForm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crear Pregunta'),
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
          ],
        ),
      ),
    );
  }
}
