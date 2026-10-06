import 'package:equatable/equatable.dart';

import '../../models/project.dart';
import '../../models/task.dart';

/// States for the project tasks list screen.
///
/// Flow: TasksInitial → TasksLoading → TasksLoaded | TasksError
///
/// [TasksLoaded] holds both the full task list and the filtered
/// result, enabling local search and status filtering without
/// re-fetching from the API.
sealed class TasksState extends Equatable {
  const TasksState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no tasks have been loaded yet.
class TasksInitial extends TasksState {
  const TasksInitial();
}

/// Loading tasks for a project.
class TasksLoading extends TasksState {
  const TasksLoading();
}

/// Tasks loaded successfully with optional local filtering applied.
class TasksLoaded extends TasksState {
  /// The parent project.
  final Project project;

  /// The complete list of tasks from the API (unfiltered).
  final List<Task> allTasks;

  /// The currently displayed tasks after search/filter is applied.
  final List<Task> filteredTasks;

  /// The current search query (empty string means no search).
  final String searchQuery;

  /// The current status filter (null means "All statuses").
  final String? statusFilter;

  const TasksLoaded({
    required this.project,
    required this.allTasks,
    required this.filteredTasks,
    this.searchQuery = '',
    this.statusFilter,
  });

  @override
  List<Object?> get props => [
        project,
        allTasks,
        filteredTasks,
        searchQuery,
        statusFilter,
      ];
}

/// Failed to load tasks.
class TasksError extends TasksState {
  final String message;

  const TasksError(this.message);

  @override
  List<Object?> get props => [message];
}
