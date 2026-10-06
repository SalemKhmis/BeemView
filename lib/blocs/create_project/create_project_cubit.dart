import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/project_repository.dart';
import 'create_project_state.dart';

/// Cubit managing the create project form submission.
///
/// Handles validation and API submission. Emits:
/// - [CreateProjectSubmitting] while the request is in-flight
/// - [CreateProjectSuccess] on success
/// - [CreateProjectError] on failure
///
/// After success or error, resets to [CreateProjectInitial] so
/// the form can be reused.
class CreateProjectCubit extends Cubit<CreateProjectState> {
  final ProjectRepository projectRepository;

  CreateProjectCubit({required this.projectRepository})
      : super(const CreateProjectInitial());

  /// Submits a new project to the API.
  ///
  /// Guards against double-submission.
  Future<void> createProject({
    required String name,
    required int organizationalUnitId,
    String? description,
    required String status,
    required String startDate,
    required String endDate,
  }) async {
    if (state is CreateProjectSubmitting) return;

    emit(const CreateProjectSubmitting());

    try {
      await projectRepository.createProject(
        name: name,
        organizationalUnitId: organizationalUnitId,
        description: description,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      emit(const CreateProjectSuccess());
    } on ProjectException catch (e) {
      emit(CreateProjectError(e.message));
    } catch (e) {
      emit(const CreateProjectError(
          'Failed to create project. Please try again.'));
    }

    // Reset to initial so the form is reusable
    emit(const CreateProjectInitial());
  }
}
