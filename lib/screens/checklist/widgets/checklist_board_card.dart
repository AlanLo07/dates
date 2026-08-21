// lib/screens/checklist/widgets/checklist_board_card.dart
import 'package:flutter/material.dart';

import '../../../models/checklist.dart';
import '../../../utils/colors.dart';

class ChecklistBoardCard extends StatelessWidget {
  final ChecklistBoard board;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ChecklistBoardCard({
    super.key,
    required this.board,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrecio = board.items.any((i) => i.precio != null);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1.5,
      shadowColor: board.color.withValues(alpha: 0.25),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: board.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(board.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      board.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.violeta,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: board.totalItems == 0 ? 0 : board.progreso,
                        minHeight: 6,
                        backgroundColor: board.color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(board.color),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          board.totalItems == 0
                              ? 'Sin items'
                              : '${board.compradosCount}/${board.totalItems} listos',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.violeta.withValues(alpha: 0.6),
                          ),
                        ),
                        if (hasPrecio) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· \$${board.precioPendiente.toStringAsFixed(0)} pendiente',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.violeta.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.violeta.withValues(alpha: 0.45),
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
