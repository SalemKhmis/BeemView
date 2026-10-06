import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../utils/status_helpers.dart';

/// A colored badge displaying a task status label.
///
/// Uses [AppTheme.statusColor] for the badge color and
/// [StatusHelpers.statusLabel] for the display text.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    final label = StatusHelpers.statusLabel(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 7,
            height: compact ? 6 : 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          SizedBox(width: compact ? 5 : 6),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
