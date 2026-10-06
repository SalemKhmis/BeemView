/// Maps API task status and priority values to human-readable labels.
///
/// Status values and their display labels are defined in the assignment
/// specification (section 10). Priority values are low, medium, high, urgent.
class StatusHelpers {
  StatusHelpers._();

  /// All possible task status API values, in display order.
  static const List<String> allStatuses = [
    'to_do',
    'in_progress',
    'on_hold',
    'review',
    'changes_requested',
    'blocked',
    'done',
    'canceled',
  ];

  /// Maps an API status value to its display label.
  static const Map<String, String> _statusLabels = {
    'to_do': 'To do',
    'in_progress': 'In progress',
    'on_hold': 'On hold',
    'review': 'Review',
    'changes_requested': 'Changes requested',
    'blocked': 'Blocked',
    'done': 'Done',
    'canceled': 'Canceled',
  };

  /// Maps an API priority value (lowercase) to its display label.
  static const Map<String, String> _priorityLabels = {
    'low': 'Low',
    'medium': 'Medium',
    'high': 'High',
    'urgent': 'Urgent',
  };

  /// Returns the display label for a given [status] API value.
  static String statusLabel(String status) {
    return _statusLabels[status] ?? status;
  }

  /// Returns the display label for a given [priority] API value.
  /// Normalizes to lowercase before lookup.
  static String priorityLabel(String priority) {
    return _priorityLabels[priority.toLowerCase()] ?? priority;
  }
}
