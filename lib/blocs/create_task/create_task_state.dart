import 'package:equatable/equatable.dart';

/// States for the create task flow.
///
/// Flow: CreateTaskInitial → CreateTaskSubmitting
///       → CreateTaskSuccess | CreateTaskError
sealed class CreateTaskState extends Equatable {
  const CreateTaskState();

  @override
  List<Object?> get props => [];
}

/// Initial state — form is ready for input.
class CreateTaskInitial extends CreateTaskState {
  const CreateTaskInitial();
}

/// Submitting the task to the API.
class CreateTaskSubmitting extends CreateTaskState {
  const CreateTaskSubmitting();
}

/// Task created successfully.
class CreateTaskSuccess extends CreateTaskState {
  const CreateTaskSuccess();
}

/// Failed to create task.
class CreateTaskError extends CreateTaskState {
  final String message;

  const CreateTaskError(this.message);

  @override
  List<Object?> get props => [message];
}
