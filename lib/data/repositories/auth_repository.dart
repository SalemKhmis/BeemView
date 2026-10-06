import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/login_request.dart';
import '../../models/login_response.dart';
import '../../models/user.dart';
import '../api/auth_api.dart';

/// Repository handling authentication, session persistence, and logout.
///
/// Responsibilities:
/// - Login via API and store the token securely.
/// - Restore a persisted session on app start and validate it.
/// - Clear session data on logout or 401.
/// - Provide the current token for the [AuthInterceptor].
class AuthRepository {
  final AuthApi _authApi;
  final FlutterSecureStorage _secureStorage;

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';

  /// The currently authenticated user, or null.
  User? _currentUser;
  User? get currentUser => _currentUser;

  /// The current bearer token, or null.
  String? _token;
  String? get token => _token;

  /// Whether a valid session exists.
  bool get isAuthenticated => _token != null && _currentUser != null;

  AuthRepository({
    required this._authApi,
    FlutterSecureStorage? secureStorage,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Authenticates the user with email, password, and subdomain.
  ///
  /// On success, persists the token securely and stores user info.
  /// Returns the [User] profile.
  ///
  /// Throws [AuthException] with a user-friendly message on failure.
  Future<User> login({
    required String email,
    required String password,
    required String subdomain,
  }) async {
    try {
      final request = LoginRequest(
        email: email.trim(),
        password: password,
        subdomain: subdomain.trim(),
      );

      final LoginResponse loginResponse = await _authApi.login(request);

      _token = loginResponse.token;
      _currentUser = loginResponse.user;

      // Persist session securely
      await _persistSession(loginResponse);

      return _currentUser!;
    } on DioException catch (e) {
      throw AuthException(_extractErrorMessage(e));
    }
  }

  /// Attempts to restore a previously persisted session.
  ///
  /// Reads the stored token and validates it by calling the
  /// `GET /users/me/profile` endpoint. If validation succeeds,
  /// the session is restored. If it fails (401 or any error),
  /// the stored session is cleared.
  ///
  /// Returns the [User] if the session is valid, or null.
  Future<User?> restoreSession() async {
    try {
      final storedToken = await _secureStorage.read(key: _tokenKey);
      if (storedToken == null || storedToken.isEmpty) {
        return null;
      }

      _token = storedToken;

      // Validate the token by fetching the current user profile
      final user = await _authApi.getCurrentUser();
      _currentUser = user;

      return user;
    } on DioException {
      // Token is invalid/expired — clear everything
      await clearSession();
      return null;
    } catch (_) {
      // Any other error (e.g., storage failure)
      await clearSession();
      return null;
    }
  }

  /// Fetches the fresh profile for the currently authenticated user
  /// from `GET /api/users/me/profile`.
  ///
  /// Updates [_currentUser] and returns the fresh [User].
  /// Throws [AuthException] on failure.
  Future<User> getProfile() async {
    try {
      final user = await _authApi.getCurrentUser();
      _currentUser = user;
      // Update locally cached name/email in secure storage if changed
      await _secureStorage.write(
        key: _userNameKey,
        value: user.fullName,
      );
      if (user.email != null) {
        await _secureStorage.write(
          key: _userEmailKey,
          value: user.email!,
        );
      }
      return user;
    } on DioException catch (e) {
      throw AuthException(_extractErrorMessage(e));
    }
  }

  /// Clears all session data (token + user state).
  ///
  /// Called on:
  /// - Manual logout (no server revocation per contract)
  /// - 401 from the [AuthInterceptor]
  /// - Failed session restore
  Future<void> clearSession() async {
    _token = null;
    _currentUser = null;

    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _userNameKey);
    await _secureStorage.delete(key: _userEmailKey);
  }

  /// Provides the current token for the [AuthInterceptor].
  /// This is passed as the `tokenProvider` callback to [ApiClient].
  Future<String?> getToken() async {
    return _token;
  }

  // ── Private helpers ─────────────────────────────────────────

  Future<void> _persistSession(LoginResponse response) async {
    await _secureStorage.write(key: _tokenKey, value: response.token);
    await _secureStorage.write(
      key: _userIdKey,
      value: response.user.id.toString(),
    );
    await _secureStorage.write(
      key: _userNameKey,
      value: response.user.fullName,
    );
    if (response.user.email != null) {
      await _secureStorage.write(
        key: _userEmailKey,
        value: response.user.email,
      );
    }
  }

  /// Extracts a user-friendly error message from a [DioException].
  ///
  /// Reads `error` or `message` from the response body.
  /// Falls back to generic messages based on status code.
  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;

    // Try to extract message from response body
    if (data is Map<String, dynamic>) {
      final error = data['error'] as String?;
      final message = data['message'] as String?;
      if (error != null && error.isNotEmpty) return error;
      if (message != null && message.isNotEmpty) return message;
    }

    // Fall back to status-code-based messages
    return switch (e.response?.statusCode) {
      400 => 'Invalid email or password. Please try again.',
      403 => 'Your account is inactive. Please contact support.',
      429 => 'Too many attempts. Please try again later.',
      500 => 'Server error. Please try again later.',
      _ => e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout
          ? 'Connection timed out. Please check your internet.'
          : e.type == DioExceptionType.connectionError
              ? 'Unable to connect. Please check your internet.'
              : 'An unexpected error occurred. Please try again.',
    };
  }
}

/// Custom exception for authentication errors with user-friendly messages.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
