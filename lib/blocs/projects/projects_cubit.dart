import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/project_repository.dart';
import 'projects_state.dart';

/// Cubit managing the projects list with pagination.
///
/// Implements a simple "load more" pattern:
/// 1. `loadProjects()` fetches the first page.
/// 2. `loadMore()` appends the next page.
/// 3. Stops when `hasMore` is false.
class ProjectsCubit extends Cubit<ProjectsState> {
  final ProjectRepository _projectRepository;

  ProjectsCubit({required this._projectRepository})
      : super(const ProjectsInitial());

  /// Loads the first page of projects (resets pagination).
  ///
  /// Used on initial load and pull-to-refresh.
  Future<void> loadProjects() async {
    emit(const ProjectsLoading());

    try {
      final response = await _projectRepository.getProjects(
        limit: 10,
        offset: 0,
      );

      emit(ProjectsLoaded(
        projects: response.items,
        hasMore: response.hasMore,
        nextOffset: response.nextOffset,
      ));
    } on ProjectException catch (e) {
      emit(ProjectsError(e.message));
    } catch (e) {
      emit(const ProjectsError('Failed to load projects. Please try again.'));
    }
  }

  /// Loads the next page of projects, appending to the existing list.
  ///
  /// Only callable when the current state is [ProjectsLoaded] and
  /// [hasMore] is true. Emits [ProjectsLoadingMore] while fetching
  /// to keep the existing list visible.
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! ProjectsLoaded || !currentState.hasMore) return;

    emit(ProjectsLoadingMore(currentProjects: currentState.projects));

    try {
      final response = await _projectRepository.getProjects(
        limit: 10,
        offset: currentState.nextOffset,
      );

      final allProjects = [
        ...currentState.projects,
        ...response.items,
      ];

      emit(ProjectsLoaded(
        projects: allProjects,
        hasMore: response.hasMore,
        nextOffset: response.nextOffset,
      ));
    } on ProjectException catch (e) {
      // On pagination error, restore the previous loaded state
      // so the user doesn't lose their list.
      emit(ProjectsLoaded(
        projects: currentState.projects,
        hasMore: currentState.hasMore,
        nextOffset: currentState.nextOffset,
      ));
      // Re-emit error so a snackbar can be shown
      emit(ProjectsError(e.message));
    } catch (e) {
      emit(ProjectsLoaded(
        projects: currentState.projects,
        hasMore: currentState.hasMore,
        nextOffset: currentState.nextOffset,
      ));
    }
  }
}
