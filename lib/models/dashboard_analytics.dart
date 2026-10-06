import 'package:equatable/equatable.dart';

import 'project.dart';
import 'task.dart';

/// Aggregated summary for a single project including task metrics.
class ProjectSummary extends Equatable {
  final Project project;
  final int totalTasks;
  final int doneTasks;
  final int inProgressTasks;
  final List<Task> tasks;

  const ProjectSummary({
    required this.project,
    required this.totalTasks,
    required this.doneTasks,
    required this.inProgressTasks,
    required this.tasks,
  });

  /// Progress ratio from 0.0 to 1.0.
  double get progress => totalTasks == 0 ? 0.0 : (doneTasks / totalTasks).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [project, totalTasks, doneTasks, inProgressTasks, tasks];
}

/// Comprehensive real-time analytics data model for the BeemView home dashboard.
class DashboardAnalytics extends Equatable {
  final int totalProjects;
  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final int reviewTasks;
  final int todoTasks;
  final int urgentTasks;
  final int highPriorityTasks;
  final int healthScore; // 0 - 100%
  final List<ProjectSummary> projectSummaries;
  final List<Task> attentionTasks;

  const DashboardAnalytics({
    required this.totalProjects,
    required this.totalTasks,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.reviewTasks,
    required this.todoTasks,
    required this.urgentTasks,
    required this.highPriorityTasks,
    required this.healthScore,
    required this.projectSummaries,
    required this.attentionTasks,
  });

  /// Completion rate percentage (0.0 to 100.0).
  double get completionRate =>
      totalTasks == 0 ? 0.0 : ((completedTasks / totalTasks) * 100).clamp(0.0, 100.0);

  @override
  List<Object?> get props => [
        totalProjects,
        totalTasks,
        completedTasks,
        inProgressTasks,
        reviewTasks,
        todoTasks,
        urgentTasks,
        highPriorityTasks,
        healthScore,
        projectSummaries,
        attentionTasks,
      ];
}
