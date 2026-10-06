import 'package:dio/dio.dart';

import '../../models/comment.dart';
import '../../models/project.dart';
import '../../models/task.dart';

/// API service for task-related endpoints.
///
/// Endpoints:
/// - `GET /api/tasks/project/:projectId` — list all tasks for a project
/// - `GET /api/tasks/:id` — get task details
/// - `PUT /api/tasks/:id` — update task status
/// - `POST /api/tasks/comment` — add a comment to a task
/// - `POST /api/tasks` — create a new task
class TaskApi {
  final Dio _dio;

  TaskApi(this._dio);

  /// Creates a new task.
  ///
  /// Required fields: [name], [status], [priority].
  /// Optional: [description], [startDate], [dueDate], [projectId],
  /// [isPrivate], [assignees].
  ///
  /// Returns the raw response data containing the created task.
  Future<Map<String, dynamic>> createTask({
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
    final response = await _dio.post(
      '/tasks',
      data: {
        'name': name,
        'description': description ?? '',
        'status': status,
        'priority': priority,
        'start_date': startDate,
        'due_date': dueDate,
        'project_id': projectId,
        'is_private': isPrivate,
        'assignees': assignees,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Fetches all tasks for a given project.
  ///
  /// This route returns the full collection without pagination.
  /// The response contains a nested `project` object and `tasks` array.
  ///
  /// Uses [Task.fromListJson] because this endpoint returns `dueDate`,
  /// `startedDate`, and capitalized priority.
  Future<({Project project, List<Task> tasks})> getProjectTasks(
    int projectId,
  ) async {
    final response = await _dio.get('/tasks/project/$projectId');
    final data = response.data as Map<String, dynamic>;

    final project = data['project'] != null
        ? Project.fromJson(data['project'] as Map<String, dynamic>)
        : Project(id: projectId, name: '');

    final tasksJson = data['tasks'] as List<dynamic>? ?? [];
    final tasks = tasksJson
        .whereType<Map<String, dynamic>>()
        .map((json) => Task.fromListJson(json, project: project))
        .toList();

    return (project: project, tasks: tasks);
  }

  /// Fetches detailed information for a single task.
  ///
  /// The response envelope is `{"task": {...}}`.
  ///
  /// Uses [Task.fromDetailJson] because this endpoint returns `due_date`,
  /// `start_date`, lowercase priority, and includes `Comments` and
  /// `Project` associations.
  Future<Task> getTaskDetails(int taskId) async {
    final response = await _dio.get('/tasks/$taskId');
    final data = response.data as Map<String, dynamic>;
    return Task.fromDetailJson(data['task'] as Map<String, dynamic>);
  }

  /// Updates the status of a task.
  ///
  /// Sends only `{"status": "<value>"}` as required by the contract.
  /// Does NOT send a progress field.
  ///
  /// Returns the raw response data (contains `message` and `task`).
  /// The caller should re-fetch task details after success to get the
  /// full detail response shape.
  Future<Map<String, dynamic>> updateTaskStatus(
    int taskId,
    String status,
  ) async {
    final response = await _dio.put(
      '/tasks/$taskId',
      data: {'status': status},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Adds a comment to a task.
  ///
  /// Called after a successful status update when the user has entered
  /// an optional note. These are separate operations and not atomic.
  ///
  /// Returns the created [Comment] from the API response.
  /// Response envelope: `{"message": "...", "comment": {...}}`
  Future<Comment> addComment(int taskId, String content) async {
    final response = await _dio.post(
      '/tasks/comment',
      data: {
        'task_id': taskId,
        'content': content,
        'mentioned_user_ids': <int>[],
      },
    );
    final data = response.data as Map<String, dynamic>;
    return Comment.fromJson(data['comment'] as Map<String, dynamic>);
  }
}
