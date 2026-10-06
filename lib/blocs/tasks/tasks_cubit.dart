import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/task_repository.dart';
import '../../models/task.dart';
import 'tasks_state.dart';

/// Cubit managing the project tasks list with local search and filtering.
///
/// Loads all tasks for a project (no pagination on this endpoint),
/// then applies search by name and filter by status client-side.
///
/// Per the assignment: "Use GET /api/tasks/project/:projectId to load
/// project tasks, then search by task name and filter by status locally.
/// Label these controls as filtering the loaded project tasks."
class TasksCubit extends Cubit<TasksState> {
  final TaskRepository _taskRepository;

  TasksCubit({required this._taskRepository}) : super(const TasksInitial());

  /// Loads all tasks for the given [projectId].
  ///
  /// Resets any active search/filter. The full list is stored in
  /// [TasksLoaded.allTasks] and initially displayed unfiltered.
  Future<void> loadProjectTasks(int projectId) async {
    emit(const TasksLoading());

    try {
      final result = await _taskRepository.getProjectTasks(projectId);

      emit(TasksLoaded(
        project: result.project,
        allTasks: result.tasks,
        filteredTasks: result.tasks,
      ));
    } on TaskException catch (e) {
      emit(TasksError(e.message));
    } catch (e) {
      emit(const TasksError('Failed to load tasks. Please try again.'));
    }
  }

  /// Searches tasks by name (case-insensitive).
  ///
  /// Combined with any active status filter.
  void searchTasks(String query) {
    final currentState = state;
    if (currentState is! TasksLoaded) return;

    final filtered = _applyFilters(
      currentState.allTasks,
      query,
      currentState.statusFilter,
    );

    emit(TasksLoaded(
      project: currentState.project,
      allTasks: currentState.allTasks,
      filteredTasks: filtered,
      searchQuery: query,
      statusFilter: currentState.statusFilter,
    ));
  }

  /// Filters tasks by status.
  ///
  /// Pass null to show all statuses. Combined with any active search query.
  void filterByStatus(String? status) {
    final currentState = state;
    if (currentState is! TasksLoaded) return;

    final filtered = _applyFilters(
      currentState.allTasks,
      currentState.searchQuery,
      status,
    );

    emit(TasksLoaded(
      project: currentState.project,
      allTasks: currentState.allTasks,
      filteredTasks: filtered,
      searchQuery: currentState.searchQuery,
      statusFilter: status,
    ));
  }

  /// Clears all active filters and search, showing all tasks.
  void clearFilters() {
    final currentState = state;
    if (currentState is! TasksLoaded) return;

    emit(TasksLoaded(
      project: currentState.project,
      allTasks: currentState.allTasks,
      filteredTasks: currentState.allTasks,
      searchQuery: '',
      statusFilter: null,
    ));
  }

  /// Applies search and status filter to the full task list.
  List<Task> _applyFilters(
    List<Task> allTasks,
    String searchQuery,
    String? statusFilter,
  ) {
    var result = allTasks;

    // Apply name search (case-insensitive)
    if (searchQuery.isNotEmpty) {
      final queryLower = searchQuery.toLowerCase();
      result = result
          .where((task) => task.name.toLowerCase().contains(queryLower))
          .toList();
    }

    // Apply status filter
    if (statusFilter != null && statusFilter.isNotEmpty) {
      result = result
          .where((task) => task.status == statusFilter)
          .toList();
    }

    return result;
  }
}
