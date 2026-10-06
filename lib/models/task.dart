import 'package:equatable/equatable.dart';

import 'comment.dart';
import 'project.dart';
import 'user.dart';

/// Represents a BeemView task with normalized fields.
///
/// **Critical normalization:** The API returns different field names and
/// priority casing depending on the endpoint:
///
/// | Field       | `/tasks/project/:id` (list) | `/tasks/:id` (detail) |
/// |-------------|-----------------------------|-----------------------|
/// | Due date    | `dueDate`                   | `due_date`            |
/// | Start date  | `startedDate`               | `start_date`          |
/// | Priority    | `"High"` (capitalized)      | `"high"` (lowercase)  |
/// | Assignees   | `Assignees`                 | `Assignees`           |
/// | Project     | `projectId` (int)           | `Project` (object)    |
///
/// This model normalizes everything:
/// - Priority is always stored lowercase.
/// - Dates are parsed from either field name.
/// - Two factory constructors: `fromListJson` and `fromDetailJson`.
class Task extends Equatable {
  final int id;
  final String name;
  final String? description;
  final String status;

  /// Always lowercase: low, medium, high, urgent.
  final String priority;
  final DateTime? dueDate;
  final DateTime? startDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// The parent project (may only have id from list, or full object from detail).
  final Project? project;

  /// Assignees list.
  final List<User> assignees;

  /// Comments (only populated from task detail endpoint).
  final List<Comment> comments;

  const Task({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    this.startDate,
    this.createdAt,
    this.updatedAt,
    this.project,
    this.assignees = const [],
    this.comments = const [],
  });

  /// Parses a task from the **project tasks list** response.
  ///
  /// Route: `GET /api/tasks/project/:projectId`
  ///
  /// Uses `dueDate`, `startedDate`, capitalized `priority`,
  /// and `projectId` (integer).
  factory Task.fromListJson(Map<String, dynamic> json, {Project? project}) {
    return Task(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'to_do',
      priority: (json['priority'] as String? ?? 'medium').toLowerCase(),
      dueDate: _parseDate(json['dueDate']),
      startDate: _parseDate(json['startedDate']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      project: project ??
          (json['projectId'] != null
              ? Project(id: json['projectId'] as int, name: '')
              : null),
      assignees: _parseAssignees(json['Assignees']),
      comments: const [],
    );
  }

  /// Parses a task from the **task detail** response.
  ///
  /// Route: `GET /api/tasks/:id`
  ///
  /// Uses `due_date`, `start_date`, lowercase `priority`,
  /// `Project` (object), `Assignees` and `Comments` arrays.
  factory Task.fromDetailJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'to_do',
      priority: (json['priority'] as String? ?? 'medium').toLowerCase(),
      dueDate: _parseDate(json['due_date']),
      startDate: _parseDate(json['start_date']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      project: json['Project'] != null
          ? Project.fromJson(json['Project'] as Map<String, dynamic>)
          : (json['project_id'] != null
              ? Project(id: json['project_id'] as int, name: '')
              : null),
      assignees: _parseAssignees(json['Assignees']),
      comments: _parseComments(json['Comments']),
    );
  }

  /// Creates a copy of this task with updated fields.
  /// Used after status update to merge new data.
  Task copyWith({
    String? name,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    DateTime? startDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Project? project,
    List<User>? assignees,
    List<Comment>? comments,
  }) {
    return Task(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      project: project ?? this.project,
      assignees: assignees ?? this.assignees,
      comments: comments ?? this.comments,
    );
  }

  /// Returns the latest comment if available.
  Comment? get latestComment =>
      comments.isNotEmpty ? comments.first : null;

  /// Returns a comma-separated string of assignee names.
  String get assigneeNames {
    if (assignees.isEmpty) return 'Unassigned';
    return assignees.map((a) => a.fullName).join(', ');
  }

  // ── Private helpers ─────────────────────────────────────────

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<User> _parseAssignees(dynamic value) {
    if (value == null || value is! List) return [];
    return value
        .whereType<Map<String, dynamic>>()
        .map((json) => User.fromJson(json))
        .toList();
  }

  static List<Comment> _parseComments(dynamic value) {
    if (value == null || value is! List) return [];
    return value
        .whereType<Map<String, dynamic>>()
        .map((json) => Comment.fromJson(json))
        .toList();
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        status,
        priority,
        dueDate,
        startDate,
        createdAt,
        updatedAt,
        project,
        assignees,
        comments,
      ];
}
