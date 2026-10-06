import 'package:dio/dio.dart';

import '../../models/login_request.dart';
import '../../models/login_response.dart';
import '../../models/user.dart';

/// API service for authentication-related endpoints.
///
/// Endpoints:
/// - `POST /api/auth/login` — authenticate with email, password, subdomain
/// - `GET /api/users/me/profile` — validate the current session token
class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  /// Authenticates a user and returns a [LoginResponse] containing
  /// the bearer token and user profile.
  ///
  /// Throws [DioException] on:
  /// - 400: invalid credentials
  /// - 403: inactive account
  /// - Network/timeout errors
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _dio.post(
      '/auth/login',
      data: request.toJson(),
    );
    return LoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Validates and retrieves the current authenticated user's profile.
  ///
  /// Endpoint: `GET /api/users/me/profile`
  /// Returns the [User] profile.
  ///
  /// Throws [DioException] on 401 if the token is invalid/expired.
  Future<User> getCurrentUser() async {
    final response = await _dio.get('/users/me/profile');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['user'] is Map<String, dynamic>) {
        return User.fromJson(data['user'] as Map<String, dynamic>);
      }
      if (data['data'] is Map<String, dynamic>) {
        return User.fromJson(data['data'] as Map<String, dynamic>);
      }
      return User.fromJson(data);
    }
    throw const FormatException('Invalid user profile response format');
  }
}
