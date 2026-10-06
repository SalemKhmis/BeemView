import 'package:dio/dio.dart';

import '../../models/paginated_response.dart';
import '../../models/project.dart';
import '../api/project_api.dart';

/// Repository for fetching and managing projects.
///
/// Wraps [ProjectApi] with error handling and provides a clean
/// interface for the presentation layer.
class ProjectRepository {
  final ProjectApi _projectApi;

  ProjectRepository({required this._projectApi});

  /// Fetches a page of projects.
  ///
  /// Implements the "load more" pagination pattern:
  /// - First call: `getProjects()` with default offset 0
  /// - Subsequent calls: `getProjects(offset: previousResponse.nextOffset)`
  /// - Stop when `!response.hasMore`
  ///
  /// Throws [ProjectException] on failure.
  Future<PaginatedResponse<Project>> getProjects({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      return await _projectApi.getProjects(
        limit: limit,
        offset: offset,
      );
    } on DioException catch (e) {
      throw ProjectException(_extractErrorMessage(e));
    }
  }

  /// Creates a new project.
  ///
  /// Throws [ProjectException] on failure.
  Future<void> createProject({
    required String name,
    required int organizationalUnitId,
    String? description,
    required String status,
    required String startDate,
    required String endDate,
  }) async {
    try {
      await _projectApi.createProject(
        name: name,
        organizationalUnitId: organizationalUnitId,
        description: description,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
    } on DioException catch (e) {
      throw ProjectException(_extractErrorMessage(e));
    }
  }

  /// Extracts a user-friendly error message from a [DioException].
  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final error = data['error'] as String?;
      final message = data['message'] as String?;
      if (error != null && error.isNotEmpty) return error;
      if (message != null && message.isNotEmpty) return message;
    }

    return switch (e.response?.statusCode) {
      403 => 'You do not have access to view projects.',
      404 => 'Projects not found.',
      429 => 'Too many requests. Please try again later.',
      500 => 'Server error. Please try again later.',
      _ => e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout
          ? 'Connection timed out. Please check your internet.'
          : e.type == DioExceptionType.connectionError
              ? 'Unable to connect. Please check your internet.'
              : 'Failed to load projects. Please try again.',
    };
  }
}

/// Custom exception for project-related errors.
class ProjectException implements Exception {
  final String message;
  const ProjectException(this.message);

  @override
  String toString() => message;
}
