import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/task_repository.dart';
import 'task_detail_state.dart';

/// Cubit managing the task detail screen.
///
/// Responsibilities:
/// - Load task details with associations (project, assignees, comments).
/// - Update task status with optional comment (two-step flow).
/// - Handle partial success (status saved but comment failed).
/// - Prevent duplicate submissions via [isSubmitting] flag.
/// - Retry failed comment without re-submitting status.
/// - Re-fetch task details after a successful update.
class TaskDetailCubit extends Cubit<TaskDetailState> {
  final TaskRepository _taskRepository;

  TaskDetailCubit({required this._taskRepository})
      : super(const TaskDetailInitial());

  /// Loads detailed information for the given [taskId].
  ///
  /// Fetches the task with all associations (Project, Assignees, Comments).
  Future<void> loadTaskDetails(int taskId) async {
    emit(const TaskDetailLoading());

    try {
      final task = await _taskRepository.getTaskDetails(taskId);
      emit(TaskDetailLoaded(task: task));
    } on TaskException catch (e) {
      emit(TaskDetailError(message: e.message));
    } catch (e) {
      emit(const TaskDetailError(
        message: 'Failed to load task details. Please try again.',
      ));
    }
  }

  /// Updates the task status and optionally adds a comment.
  ///
  /// **Flow:**
  /// 1. Set `isSubmitting = true` to disable the save button.
  /// 2. Save the status via `PUT /tasks/:id`.
  /// 3. If a comment is provided, post it via `POST /tasks/comment`.
  /// 4. Re-fetch task details for the updated response shape.
  ///
  /// **Outcomes:**
  /// - Full success: status + comment saved → [TaskDetailUpdateSuccess]
  /// - Partial success: status saved, comment failed →
  ///   [TaskDetailUpdateSuccess] with [commentError]
  /// - Failure: status not saved → [TaskDetailError]
  ///
  /// **Duplicate prevention:** Ignores calls while [isSubmitting] is true.
  Future<void> updateStatus({
    required int taskId,
    required String status,
    String? comment,
  }) async {
    // Prevent duplicate submissions
    final currentState = state;
    if (currentState is TaskDetailLoaded && currentState.isSubmitting) {
      return;
    }

    // Set submitting flag
    if (currentState is TaskDetailLoaded) {
      emit(currentState.copyWith(isSubmitting: true));
    }

    try {
      final result = await _taskRepository.updateTaskWithComment(
        taskId: taskId,
        status: status,
        comment: comment,
      );

      emit(TaskDetailUpdateSuccess(
        task: result.task,
        commentError: result.commentError,
      ));
    } on TaskException catch (e) {
      // Status update failed — restore the loaded state with error
      final previousTask =
          currentState is TaskDetailLoaded ? currentState.task : null;
      emit(TaskDetailError(
        message: e.message,
        previousTask: previousTask,
      ));
    } catch (e) {
      final previousTask =
          currentState is TaskDetailLoaded ? currentState.task : null;
      emit(TaskDetailError(
        message: 'Failed to update task. Please try again.',
        previousTask: previousTask,
      ));
    }
  }

  /// Retries posting a comment after a partial success.
  ///
  /// Only retries the comment — does NOT re-submit the status.
  /// Called when the user clicks "Retry" after seeing
  /// "Status saved, comment failed".
  ///
  /// **Important:** Does not automatically retry on ambiguous network
  /// failures to avoid duplicating comments.
  Future<void> retryComment({
    required int taskId,
    required String comment,
  }) async {
    final currentState = state;
    if (currentState is TaskDetailUpdateSuccess) {
      // Show submitting state
      emit(TaskDetailLoaded(
        task: currentState.task,
        isSubmitting: true,
      ));

      try {
        await _taskRepository.addComment(taskId, comment.trim());

        // Re-fetch task details for the updated comment list
        final updatedTask = await _taskRepository.getTaskDetails(taskId);
        emit(TaskDetailUpdateSuccess(task: updatedTask));
      } on TaskException catch (e) {
        // Comment retry failed — show partial success again
        emit(TaskDetailUpdateSuccess(
          task: currentState.task,
          commentError: e.message,
        ));
      } catch (e) {
        emit(TaskDetailUpdateSuccess(
          task: currentState.task,
          commentError: 'Failed to post comment. Please try again.',
        ));
      }
    }
  }

  /// Refreshes the task details (e.g., pull-to-refresh).
  ///
  /// Preserves the current task data while reloading.
  Future<void> refreshTaskDetails(int taskId) async {
    try {
      final task = await _taskRepository.getTaskDetails(taskId);
      emit(TaskDetailLoaded(task: task));
    } on TaskException catch (e) {
      final previousTask =
          state is TaskDetailLoaded ? (state as TaskDetailLoaded).task : null;
      emit(TaskDetailError(
        message: e.message,
        previousTask: previousTask,
      ));
    }
  }

  /// Resets the state back to loaded after an update success
  /// (so the user can make further updates).
  void acknowledgeUpdate() {
    final currentState = state;
    if (currentState is TaskDetailUpdateSuccess) {
      emit(TaskDetailLoaded(task: currentState.task));
    }
  }
}
