import 'user.dart';

/// Login response data transfer object.
///
/// Parsed from the `HTTP 200` response of `POST /api/auth/login`.
/// Contains the bearer token, user info, and additional metadata.
class LoginResponse {
  final String token;
  final User user;
  final String? message;

  const LoginResponse({
    required this.token,
    required this.user,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      message: json['message'] as String?,
    );
  }
}
