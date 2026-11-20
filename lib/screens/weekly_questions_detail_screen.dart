import 'package:flutter/material.dart';
import '../models/weekly_question.dart';
import '../services/weekly_questions_service.dart';
import 'package:intl/intl.dart';

class WeeklyQuestionsDetailScreen extends StatelessWidget {
  final WeeklyQuestion question;

  const WeeklyQuestionsDetailScreen({
    super.key,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la Pregunta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pregunta principal
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
                    label: Text(question.category),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.text,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Información
            _buildInfoSection(context),
            const SizedBox(height: 24),

            // Respuestas
            _buildAnswersSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                'Estado:',
                _getStatusText(question.status),
                context,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Categoría:',
                question.category,
                context,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Versión del catálogo:',
                question.catalogVersion.toString(),
                context,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Presentada:',
                question.presented ? 'Sí' : 'No',
                context,
              ),
              if (question.firstPresentedAt != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Presentada el:',
                  DateFormat('d/MM/y H:mm', 'es_ES').format(
                    question.firstPresentedAt!,
                  ),
                  context,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildAnswersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Respuestas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (question.answers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Sin respuestas aún',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
          )
        else
          Column(
            children: question.answers.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAnswerItem(entry.key, entry.value, context),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAnswerItem(
    String userSub,
    Answer answer,
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userSub,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            answer.text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Actualizado: ${DateFormat('d/MM/y H:mm', 'es_ES').format(answer.updatedAt)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[500],
                ),
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
}
