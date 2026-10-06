import 'package:equatable/equatable.dart';

import '../../models/task.dart';

/// States for the task detail screen.
///
/// Covers: loading, loaded, updating (status/comment), update success
/// (full or partial), and errors.
sealed class TaskDetailState extends Equatable {
  const TaskDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no task detail loaded yet.
class TaskDetailInitial extends TaskDetailState {
  const TaskDetailInitial();
}

/// Loading task details from the API.
class TaskDetailLoading extends TaskDetailState {
  const TaskDetailLoading();
}

/// Task details loaded successfully.
class TaskDetailLoaded extends TaskDetailState {
  final Task task;

  /// Whether a status update is currently in progress.
  /// Used to disable the save button and prevent duplicate submissions.
  final bool isSubmitting;

  const TaskDetailLoaded({
    required this.task,
    this.isSubmitting = false,
  });

  TaskDetailLoaded copyWith({
    Task? task,
    bool? isSubmitting,
  }) {
    return TaskDetailLoaded(
      task: task ?? this.task,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [task, isSubmitting];
}

/// Status update succeeded. The task has been refreshed.
///
/// If [commentError] is non-null, the status was saved but the
/// comment failed (partial success). The UI should:
/// - Show the saved status
/// - Inform the user about the comment failure
/// - Preserve the note and offer retry for the comment only
class TaskDetailUpdateSuccess extends TaskDetailState {
  final Task task;

  /// Error message if the comment failed, or null for full success.
  final String? commentError;

  /// Whether this is a full success (status + comment both saved).
  bool get isFullSuccess => commentError == null;

  /// Whether status saved but the comment failed.
  bool get isPartialSuccess => commentError != null;

  const TaskDetailUpdateSuccess({
    required this.task,
    this.commentError,
  });

  @override
  List<Object?> get props => [task, commentError];
}

/// Failed to load task details or update the task.
class TaskDetailError extends TaskDetailState {
  final String message;

  /// The previously loaded task, if available.
  /// Allows the UI to still show task data while showing the error.
  final Task? previousTask;

  const TaskDetailError({
    required this.message,
    this.previousTask,
  });

  @override
  List<Object?> get props => [message, previousTask];
}
