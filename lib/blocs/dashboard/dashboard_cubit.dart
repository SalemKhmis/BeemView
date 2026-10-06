import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../models/dashboard_analytics.dart';
import '../../models/task.dart';
import 'dashboard_state.dart';

/// Cubit managing real-time analytics aggregation for the home screen.
///
/// Fetches projects and task lists across projects, computing
/// health score, status breakdowns, priority distribution, and
/// attention-required tasks.
class DashboardCubit extends Cubit<DashboardState> {
  final ProjectRepository projectRepository;
  final TaskRepository taskRepository;

  DashboardCubit({
    required this.projectRepository,
    required this.taskRepository,
  }) : super(const DashboardInitial());

  /// Loads or refreshes workspace analytics.
  Future<void> loadDashboard() async {
    // Only emit loading if not already in a loaded state to allow smooth pull-to-refresh
    if (state is! DashboardLoaded) {
      emit(const DashboardLoading());
    }

    try {
      // 1. Fetch recent projects
      final projectsResponse = await projectRepository.getProjects(
        limit: 15,
        offset: 0,
      );
      final projects = projectsResponse.items;

      if (projects.isEmpty) {
        emit(const DashboardLoaded(
          DashboardAnalytics(
            totalProjects: 0,
            totalTasks: 0,
            completedTasks: 0,
            inProgressTasks: 0,
            reviewTasks: 0,
            todoTasks: 0,
            urgentTasks: 0,
            highPriorityTasks: 0,
            healthScore: 100,
            projectSummaries: [],
            attentionTasks: [],
          ),
        ));
        return;
      }

      // 2. Concurrently fetch tasks for each project
      final tasksFutures = projects.map((p) async {
        try {
          final result = await taskRepository.getProjectTasks(p.id);
          return (project: p, tasks: result.tasks);
        } catch (_) {
          return (project: p, tasks: <Task>[]);
        }
      });

      final projectResults = await Future.wait(tasksFutures);

      // 3. Aggregate metrics
      int totalTasks = 0;
      int completedTasks = 0;
      int inProgressTasks = 0;
      int reviewTasks = 0;
      int todoTasks = 0;
      int urgentTasks = 0;
      int highPriorityTasks = 0;
      int overdueTasks = 0;

      final now = DateTime.now();
      final List<ProjectSummary> summaries = [];
      final List<Task> allAttentionTasks = [];

      for (final result in projectResults) {
        final tasks = result.tasks;
        int pDone = 0;
        int pInProgress = 0;

        for (final task in tasks) {
          totalTasks++;
          final status = task.status.toLowerCase();
          final priority = task.priority.toLowerCase();

          if (status == 'done') {
            completedTasks++;
            pDone++;
          } else if (status == 'in_progress') {
            inProgressTasks++;
            pInProgress++;
          } else if (status == 'review') {
            reviewTasks++;
          } else if (status == 'to_do') {
            todoTasks++;
          }

          if (priority == 'urgent') {
            urgentTasks++;
          } else if (priority == 'high') {
            highPriorityTasks++;
          }

          // Check overdue status
          final isOverdue = task.dueDate != null &&
              task.dueDate!.isBefore(now) &&
              status != 'done' &&
              status != 'canceled';

          if (isOverdue) {
            overdueTasks++;
          }

          // Flag for attention if urgent, high, or overdue and not completed
          if (status != 'done' && status != 'canceled') {
            if (priority == 'urgent' || priority == 'high' || isOverdue) {
              allAttentionTasks.add(task);
            }
          }
        }

        summaries.add(ProjectSummary(
          project: result.project,
          totalTasks: tasks.length,
          doneTasks: pDone,
          inProgressTasks: pInProgress,
          tasks: tasks,
        ));
      }

      // Sort attention tasks: urgent first, then high, then earliest due date
      allAttentionTasks.sort((a, b) {
        final aUrgent = a.priority.toLowerCase() == 'urgent' ? 1 : 0;
        final bUrgent = b.priority.toLowerCase() == 'urgent' ? 1 : 0;
        if (aUrgent != bUrgent) return bUrgent.compareTo(aUrgent);

        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        }
        if (a.dueDate != null) return -1;
        if (b.dueDate != null) return 1;
        return 0;
      });

      // 4. Calculate Health Score
      int healthScore = 100;
      if (totalTasks > 0) {
        final rawRatio = (completedTasks * 1.0 +
                reviewTasks * 0.85 +
                inProgressTasks * 0.65 +
                todoTasks * 0.35) /
            totalTasks;
        final penalty = overdueTasks * 4;
        final calculated = ((rawRatio * 100) - penalty).round();
        healthScore = calculated.clamp(35, 98);
        if (completedTasks == totalTasks && totalTasks > 0) {
          healthScore = 100;
        }
      }

      emit(DashboardLoaded(
        DashboardAnalytics(
          totalProjects: projectsResponse.total > 0 ? projectsResponse.total : projects.length,
          totalTasks: totalTasks,
          completedTasks: completedTasks,
          inProgressTasks: inProgressTasks,
          reviewTasks: reviewTasks,
          todoTasks: todoTasks,
          urgentTasks: urgentTasks,
          highPriorityTasks: highPriorityTasks,
          healthScore: healthScore,
          projectSummaries: summaries,
          attentionTasks: allAttentionTasks.take(5).toList(),
        ),
      ));
    } on ProjectException catch (e) {
      emit(DashboardError(e.message));
    } catch (_) {
      emit(const DashboardError('Failed to load real-time analytics.'));
    }
  }
}
