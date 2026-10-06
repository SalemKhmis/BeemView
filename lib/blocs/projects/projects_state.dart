import 'package:equatable/equatable.dart';

import '../../models/project.dart';

/// States for the projects list screen.
///
/// Flow: ProjectsInitial → ProjectsLoading → ProjectsLoaded | ProjectsError
///       ProjectsLoaded → ProjectsLoadingMore → ProjectsLoaded (pagination)
sealed class ProjectsState extends Equatable {
  const ProjectsState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no projects have been loaded yet.
class ProjectsInitial extends ProjectsState {
  const ProjectsInitial();
}

/// Loading the first page of projects.
class ProjectsLoading extends ProjectsState {
  const ProjectsLoading();
}

/// Projects loaded successfully.
class ProjectsLoaded extends ProjectsState {
  /// All projects loaded so far (accumulated across pages).
  final List<Project> projects;

  /// Whether there are more projects available to load.
  final bool hasMore;

  /// The offset for the next page request.
  final int nextOffset;

  const ProjectsLoaded({
    required this.projects,
    required this.hasMore,
    required this.nextOffset,
  });

  @override
  List<Object?> get props => [projects, hasMore, nextOffset];
}

/// Currently loading more projects (pagination in progress).
/// Keeps the existing list visible while loading.
class ProjectsLoadingMore extends ProjectsState {
  final List<Project> currentProjects;

  const ProjectsLoadingMore({required this.currentProjects});

  @override
  List<Object?> get props => [currentProjects];
}

/// Failed to load projects.
class ProjectsError extends ProjectsState {
  final String message;

  const ProjectsError(this.message);

  @override
  List<Object?> get props => [message];
}
