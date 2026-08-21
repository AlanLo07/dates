// lib/screens/checklist/widgets/checklist_item_tile.dart
import 'package:flutter/material.dart';

import '../../../models/checklist.dart';
import '../../../utils/colors.dart';

class ChecklistItemTile extends StatelessWidget {
  final ChecklistItem item;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: AppColors.error.withValues(alpha: 0.85),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Checkbox(
          value: item.comprado,
          activeColor: AppColors.violeta,
          onChanged: onToggle,
        ),
        title: Row(
          children: [
            if (item.emoji != null && item.emoji!.isNotEmpty) ...[
              Text(item.emoji!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                item.nombre,
                style: TextStyle(
                  decoration: item.comprado
                      ? TextDecoration.lineThrough
                      : null,
                  color: item.comprado
                      ? AppColors.violeta.withValues(alpha: 0.4)
                      : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: item.precio != null
            ? Text(
                '\$${item.precio!.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.violeta.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: item.prioridad.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
