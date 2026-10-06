import 'package:intl/intl.dart';

/// Date formatting helpers for consistent display.
class DateFormatters {
  DateFormatters._();

  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy · HH:mm');
  static final DateFormat _relativeDate = DateFormat('MMM d');

  /// Formats a [DateTime] as "Oct 6, 2026".
  static String formatDate(DateTime? date) {
    if (date == null) return '—';
    return _dateFormat.format(date.toLocal());
  }

  /// Formats a [DateTime] as "Oct 6, 2026 · 14:30".
  static String formatDateTime(DateTime? date) {
    if (date == null) return '—';
    return _dateTimeFormat.format(date.toLocal());
  }

  /// Formats a [DateTime] as relative if within the current year,
  /// otherwise includes the year.
  static String formatRelative(DateTime? date) {
    if (date == null) return '—';
    final local = date.toLocal();
    final now = DateTime.now();
    if (local.year == now.year) {
      return _relativeDate.format(local);
    }
    return _dateFormat.format(local);
  }
}
