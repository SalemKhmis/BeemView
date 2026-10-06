import 'package:equatable/equatable.dart';

/// States for the create project flow.
///
/// Flow: CreateProjectInitial → CreateProjectSubmitting
///       → CreateProjectSuccess | CreateProjectError
sealed class CreateProjectState extends Equatable {
  const CreateProjectState();

  @override
  List<Object?> get props => [];
}

/// Initial state — form is ready for input.
class CreateProjectInitial extends CreateProjectState {
  const CreateProjectInitial();
}

/// Submitting the project to the API.
class CreateProjectSubmitting extends CreateProjectState {
  const CreateProjectSubmitting();
}

/// Project created successfully.
class CreateProjectSuccess extends CreateProjectState {
  const CreateProjectSuccess();
}

/// Failed to create project.
class CreateProjectError extends CreateProjectState {
  final String message;

  const CreateProjectError(this.message);

  @override
  List<Object?> get props => [message];
}
