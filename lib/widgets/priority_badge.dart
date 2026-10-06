import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../utils/status_helpers.dart';

/// A colored badge displaying a task priority label.
///
/// Uses [AppTheme.priorityColor] for the badge color and
/// [StatusHelpers.priorityLabel] for the display text.
class PriorityBadge extends StatelessWidget {
  final String priority;
  final bool compact;

  const PriorityBadge(
      {super.key, required this.priority, this.compact = false});

  IconData _icon() {
    return switch (priority.toLowerCase()) {
      'urgent' => Icons.keyboard_double_arrow_up_rounded,
      'high' => Icons.keyboard_arrow_up_rounded,
      'medium' => Icons.remove_rounded,
      'low' => Icons.keyboard_arrow_down_rounded,
      _ => Icons.remove_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.priorityColor(priority);
    final label = StatusHelpers.priorityLabel(priority);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: compact ? 13 : 15, color: color),
          SizedBox(width: compact ? 2 : 3),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
