import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/task_repository.dart';
import 'create_task_state.dart';

/// Cubit managing the create task form submission.
///
/// Handles validation and API submission. Emits:
/// - [CreateTaskSubmitting] while the request is in-flight
/// - [CreateTaskSuccess] on success
/// - [CreateTaskError] on failure
///
/// After success or error, resets to [CreateTaskInitial] so
/// the form can be reused.
class CreateTaskCubit extends Cubit<CreateTaskState> {
  final TaskRepository taskRepository;

  CreateTaskCubit({required this.taskRepository})
      : super(const CreateTaskInitial());

  /// Submits a new task to the API.
  ///
  /// Guards against double-submission.
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
    if (state is CreateTaskSubmitting) return;

    emit(const CreateTaskSubmitting());

    try {
      await taskRepository.createTask(
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
      emit(const CreateTaskSuccess());
    } on TaskException catch (e) {
      emit(CreateTaskError(e.message));
    } catch (e) {
      emit(const CreateTaskError(
          'Failed to create task. Please try again.'));
    }

    // Reset to initial so the form is reusable
    emit(const CreateTaskInitial());
  }
}
