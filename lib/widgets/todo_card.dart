import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../models/todo_model.dart';
import '../utils/constants.dart';
import 'priority_badge.dart';

class TodoCard extends StatelessWidget {
  final TodoModel    todo;
  final String       decryptedNote;
  final bool         isOverdue;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int          index;

  const TodoCard({
    super.key,
    required this.todo,
    required this.decryptedNote,
    required this.isOverdue,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final completed = todo.completed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap:        onEdit,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Checkbox ──────────────────────────────────────────
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width:  26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed ? cs.primary : Colors.transparent,
                    border: Border.all(
                      color: completed
                          ? cs.primary
                          : (isDark ? Colors.white38 : Colors.black26),
                      width: 2,
                    ),
                  ),
                  child: completed
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // ── Content ───────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration: completed ? TextDecoration.lineThrough : null,
                            color: completed
                                ? (isDark ? Colors.white38 : Colors.black38)
                                : null,
                          ),
                    ),
                    if (decryptedNote.isNotEmpty &&
                        !decryptedNote.startsWith('[')) ...[
                      const SizedBox(height: 4),
                      Text(
                        decryptedNote,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing:    6,
                      runSpacing: 4,
                      children: [
                        PriorityBadge(priority: todo.priority),
                        if (todo.dueDate != null)
                          _DueDateChip(
                            date:      todo.dueDate!,
                            isOverdue: isOverdue,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Actions ───────────────────────────────────────────
              Column(
                children: [
                  _ActionIcon(
                    icon:    Icons.edit_outlined,
                    color:   isDark ? Colors.white54 : Colors.black45,
                    onTap:   onEdit,
                    tooltip: 'Edit',
                  ),
                  const SizedBox(height: 4),
                  _ActionIcon(
                    icon:    Icons.delete_outline,
                    color:   Constants.prioHigh.withOpacity(0.7),
                    onTap:   onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.12, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}

class _DueDateChip extends StatelessWidget {
  final DateTime date;
  final bool     isOverdue;
  const _DueDateChip({required this.date, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    final color = isOverdue ? Constants.prioHigh : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.calendar_today_outlined,
            size:  12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            DateFormat('MMM d').format(date),
            style: TextStyle(
              color:      color,
              fontSize:   11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;
  final String       tooltip;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child:   Icon(icon, size: 20, color: color),
          ),
        ),
      );
}