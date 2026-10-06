import 'package:dio/dio.dart';

import '../../models/comment.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../api/task_api.dart';

/// Repository for fetching tasks, updating status, and adding comments.
///
/// Wraps [TaskApi] with error handling and provides a clean
/// interface for the presentation layer. Handles the critical
/// two-step status-then-comment update flow.
class TaskRepository {
  final TaskApi _taskApi;

  TaskRepository({required this._taskApi});

  /// Fetches all tasks for a project.
  ///
  /// Returns the project info and full task list (no pagination).
  /// Tasks are parsed using [Task.fromListJson] with normalized fields.
  ///
  /// Throws [TaskException] on failure.
  Future<({Project project, List<Task> tasks})> getProjectTasks(
    int projectId,
  ) async {
    try {
      return await _taskApi.getProjectTasks(projectId);
    } on DioException catch (e) {
      throw TaskException(_extractErrorMessage(e));
    }
  }

  /// Fetches detailed information for a single task.
  ///
  /// Returns a [Task] with full associations (Project, Assignees, Comments).
  /// Parsed using [Task.fromDetailJson] with normalized fields.
  ///
  /// Throws [TaskException] on failure.
  Future<Task> getTaskDetails(int taskId) async {
    try {
      return await _taskApi.getTaskDetails(taskId);
    } on DioException catch (e) {
      throw TaskException(_extractErrorMessage(e));
    }
  }

  /// Updates the status of a task.
  ///
  /// Sends only `{"status": "<value>"}` — no progress field.
  /// Returns the raw response map for success/error inspection.
  ///
  /// After success, the caller should re-fetch task details to get
  /// the full detail response shape.
  ///
  /// Throws [TaskException] on failure.
  Future<void> updateTaskStatus(int taskId, String status) async {
    try {
      await _taskApi.updateTaskStatus(taskId, status);
    } on DioException catch (e) {
      throw TaskException(_extractErrorMessage(e));
    }
  }

  /// Adds a comment to a task.
  ///
  /// Called as a separate step after a successful status update.
  /// These two operations are NOT atomic.
  ///
  /// Returns the created [Comment].
  ///
  /// Throws [TaskException] on failure.
  Future<Comment> addComment(int taskId, String content) async {
    try {
      return await _taskApi.addComment(taskId, content);
    } on DioException catch (e) {
      throw TaskException(_extractErrorMessage(e));
    }
  }

  /// Creates a new task.
  ///
  /// Throws [TaskException] on failure.
  Future<void> createTask({
    required String name,
    String? description,
    required String status,
    required String priority,
    String? startDate,
    String? dueDate,
    int? projectId,
    bool isPrivate = false,
    List<int> assignees = const [],
  }) async {
    try {
      await _taskApi.createTask(
        name: name,
        description: description,
        status: status,
        priority: priority,
        startDate: startDate,
        dueDate: dueDate,
        projectId: projectId,
        isPrivate: isPrivate,
        assignees: assignees,
      );
    } on DioException catch (e) {
      throw TaskException(_extractErrorMessage(e));
    }
  }

  /// Performs the full status update + optional comment flow.
  ///
  /// 1. Updates the task status.
  /// 2. If [comment] is non-empty, posts it as a separate comment.
  /// 3. Re-fetches task details for the updated data.
  ///
  /// Returns a [TaskUpdateResult] indicating:
  /// - Full success (status + comment saved)
  /// - Partial success (status saved, comment failed)
  /// - Failure (status not saved)
  Future<TaskUpdateResult> updateTaskWithComment({
    required int taskId,
    required String status,
    String? comment,
  }) async {
    // Step 1: Update status
    try {
      await updateTaskStatus(taskId, status);
    } on TaskException {
      // Status failed — don't attempt comment
      rethrow;
    }

    // Step 2: If comment provided, attempt to post it
    String? commentError;
    if (comment != null && comment.trim().isNotEmpty) {
      try {
        await addComment(taskId, comment.trim());
      } on TaskException catch (e) {
        // Status succeeded but comment failed — partial success
        commentError = e.message;
      }
    }

    // Step 3: Re-fetch task details for fresh data
    final updatedTask = await getTaskDetails(taskId);

    return TaskUpdateResult(
      task: updatedTask,
      statusSaved: true,
      commentError: commentError,
    );
  }

  /// Extracts a user-friendly error message from a [DioException].
  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final error = data['error'] as String?;
      final message = data['message'] as String?;

      // Check for validation error details
      final details = data['details'] as List<dynamic>?;
      if (details != null && details.isNotEmpty) {
        final firstDetail = details.first;
        if (firstDetail is Map<String, dynamic>) {
          final detailMsg = firstDetail['message'] as String?;
          if (detailMsg != null) return detailMsg;
        }
      }

      if (error != null && error.isNotEmpty) return error;
      if (message != null && message.isNotEmpty) return message;
    }

    return switch (e.response?.statusCode) {
      400 => 'Invalid request. Please check your input.',
      403 => 'You do not have permission for this action.',
      404 => 'Task or project not found.',
      429 => 'Too many requests. Please try again later.',
      500 => 'Server error. Please try again later.',
      _ => e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout
          ? 'Connection timed out. Please check your internet.'
          : e.type == DioExceptionType.connectionError
              ? 'Unable to connect. Please check your internet.'
              : 'An unexpected error occurred. Please try again.',
    };
  }
}

/// Result of a task status update with optional comment.
///
/// Used to communicate partial success (status saved but comment failed)
/// back to the UI layer.
class TaskUpdateResult {
  /// The refreshed task after the update.
  final Task task;

  /// Whether the status was saved successfully.
  final bool statusSaved;

  /// Error message if the comment failed, or null if it succeeded
  /// or was not attempted.
  final String? commentError;

  /// Whether everything succeeded (status + comment if attempted).
  bool get isFullSuccess => statusSaved && commentError == null;

  /// Whether the status saved but the comment failed.
  bool get isPartialSuccess => statusSaved && commentError != null;

  const TaskUpdateResult({
    required this.task,
    required this.statusSaved,
    this.commentError,
  });
}

/// Custom exception for task-related errors.
class TaskException implements Exception {
  final String message;
  const TaskException(this.message);

  @override
  String toString() => message;
}
