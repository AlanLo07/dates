import 'package:flutter/material.dart';
import '../../models/weekly_question.dart';

class WeeklyQuestionCard extends StatelessWidget {
  final WeeklyQuestion question;
  final VoidCallback? onTap;

  const WeeklyQuestionCard({
    super.key,
    required this.question,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getBorderColor(),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Categoría
              Chip(
                label: Text(
                  question.category,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                backgroundColor: _getCategoryColor().withAlpha(200),
              ),
              const SizedBox(height: 12),

              // Texto de la pregunta
              Text(
                question.text,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Estado y progreso
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      _getStatusLabel(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _buildProgressIndicator(context),
                ],
              ),

              // Indicadores de respuestas
              if (question.answers.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildAnswerIndicators(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getBorderColor() {
    if (question.locked) return Colors.grey[400]!;
    switch (question.status) {
      case 'completed':
        return Colors.green[400]!;
      case 'partial':
        return Colors.amber[400]!;
      case 'pending':
        return Colors.orange[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  Color _getCategoryColor() {
    switch (question.category.toLowerCase()) {
      case 'divertidas':
        return Colors.yellow;
      case 'profundas':
        return Colors.purple;
      case 'romanticas':
        return Colors.pink;
      case 'absurdas':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor() {
    switch (question.status) {
      case 'completed':
        return Colors.green[700]!;
      case 'partial':
        return Colors.amber[700]!;
      case 'pending':
        return Colors.orange[700]!;
      case 'unseen':
        return Colors.grey[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getStatusLabel() {
    if (question.locked) {
      return '🔒 Bloqueada';
    }
    switch (question.status) {
      case 'completed':
        return '✅ Completada';
      case 'partial':
        return '⏳ Una respuesta';
      case 'pending':
        return '📝 Sin respuestas';
      case 'unseen':
        return '👁️ Nueva';
      default:
        return question.status;
    }
  }

  Widget _buildProgressIndicator(BuildContext context) {
    int answered = question.answers.length;
    const int total = 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withAlpha(50),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$answered/$total',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _getStatusColor(),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildAnswerIndicators(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final entry in question.answers.entries)
          Tooltip(
            message: entry.key,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.check, size: 12, color: Colors.green),
            ),
          ),
      ],
    );
  }
}
