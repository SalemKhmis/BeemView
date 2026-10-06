import 'package:dio/dio.dart';

import '../../config/api_config.dart';
import '../../models/paginated_response.dart';
import '../../models/project.dart';

/// API service for project-related endpoints.
///
/// Endpoints:
/// - `GET /api/projects` — list projects with pagination
/// - `POST /api/projects` — create a new project
class ProjectApi {
  final Dio _dio;

  ProjectApi(this._dio);

  /// Creates a new project.
  ///
  /// Required fields: [name], [organizationalUnitId], [status],
  /// [startDate], [endDate].
  /// Optional: [description].
  ///
  /// Returns the raw response data containing the created project.
  Future<Map<String, dynamic>> createProject({
    required String name,
    required int organizationalUnitId,
    String? description,
    required String status,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.post(
      '/projects',
      data: {
        'name': name,
        'organizational_unit_id': organizationalUnitId,
        'description': description ?? '',
        'status': status,
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Fetches a paginated list of projects accessible to the authenticated user.
  ///
  /// [limit] defaults to [ApiConfig.defaultPageLimit] (10).
  /// [offset] defaults to [ApiConfig.defaultPageOffset] (0).
  ///
  /// Handles both response envelopes:
  /// - Normal: `{"total": N, "count": N, "limit": 10, "offset": 0, "data": [...]}`
  /// - Empty:  `{"result": [], "count": 0}`
  Future<PaginatedResponse<Project>> getProjects({
    int limit = ApiConfig.defaultPageLimit,
    int offset = ApiConfig.defaultPageOffset,
  }) async {
    final response = await _dio.get(
      '/projects',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Project.fromJson(json),
    );
  }
}
