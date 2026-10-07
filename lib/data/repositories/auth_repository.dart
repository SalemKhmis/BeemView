import 'dart:convert';

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

  static const _defaultAndroidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
  );
  static const _defaultIosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  static const _tokenKey = 'auth_token';
  static const _userJsonKey = 'auth_user_json';
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
  })  : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: _defaultAndroidOptions,
              iOptions: _defaultIosOptions,
            );

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
  /// Reads the stored token and cached user. If present, validates with
  /// the server. If the server is unreachable (offline/timeout/server error),
  /// the session remains active with the cached user. Only a 401 Unauthorized
  /// response clears the session.
  ///
  /// Returns the [User] if the session is valid, or null.
  Future<User?> restoreSession() async {
    try {
      final storedToken = await _readStorage(_tokenKey);
      if (storedToken == null || storedToken.isEmpty) {
        return null;
      }

      _token = storedToken;

      // 1. Restore the locally cached user first
      User? restoredUser;
      final cachedUserJson = await _readStorage(_userJsonKey);
      if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
        try {
          final Map<String, dynamic> userMap = jsonDecode(cachedUserJson);
          restoredUser = User.fromJson(userMap);
        } catch (_) {}
      }

      // Fallback: reconstruct from individual stored fields
      if (restoredUser == null) {
        final idStr = await _readStorage(_userIdKey);
        final name = await _readStorage(_userNameKey);
        final email = await _readStorage(_userEmailKey);
        if (name != null && name.isNotEmpty) {
          restoredUser = User(
            id: int.tryParse(idStr ?? '0') ?? 0,
            fullName: name,
            email: email,
          );
        }
      }

      if (restoredUser != null) {
        _currentUser = restoredUser;
      }

      // 2. Validate/refresh user profile from server
      try {
        final freshUser = await _authApi.getCurrentUser();
        _currentUser = freshUser;
        try {
          await _writeStorage(_userJsonKey, jsonEncode(freshUser.toJson()));
          await _writeStorage(_userNameKey, freshUser.fullName);
          if (freshUser.email != null) {
            await _writeStorage(_userEmailKey, freshUser.email!);
          }
        } catch (_) {}
        return freshUser;
      } on DioException catch (dioErr) {
        // Only if the server explicitly rejects the token with 401 Unauthorized
        if (dioErr.response?.statusCode == 401) {
          await clearSession();
          return null;
        }
        // Network timeout / offline / connection errors: keep session alive!
        if (_currentUser != null) {
          return _currentUser;
        }
        final fallback = User(id: 0, fullName: 'User');
        _currentUser = fallback;
        return fallback;
      } catch (_) {
        // Non-401 unexpected error (e.g. format issues): keep session alive
        if (_currentUser != null) {
          return _currentUser;
        }
        final fallback = User(id: 0, fullName: 'User');
        _currentUser = fallback;
        return fallback;
      }
    } catch (_) {
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
      try {
        await _writeStorage(_userJsonKey, jsonEncode(user.toJson()));
        await _writeStorage(_userNameKey, user.fullName);
        if (user.email != null) {
          await _writeStorage(_userEmailKey, user.email!);
        }
      } catch (_) {}
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
  /// - Explicit token invalidation
  Future<void> clearSession() async {
    _token = null;
    _currentUser = null;

    await _deleteStorage(_tokenKey);
    await _deleteStorage(_userJsonKey);
    await _deleteStorage(_userIdKey);
    await _deleteStorage(_userNameKey);
    await _deleteStorage(_userEmailKey);
  }

  /// Provides the current token for the [AuthInterceptor].
  /// This is passed as the `tokenProvider` callback to [ApiClient].
  Future<String?> getToken() async {
    if (_token != null && _token!.isNotEmpty) return _token;
    _token = await _readStorage(_tokenKey);
    return _token;
  }

  // ── Private helpers ─────────────────────────────────────────

  Future<void> _persistSession(LoginResponse response) async {
    await _writeStorage(_tokenKey, response.token);
    try {
      await _writeStorage(_userJsonKey, jsonEncode(response.user.toJson()));
    } catch (_) {}
    await _writeStorage(_userIdKey, response.user.id.toString());
    await _writeStorage(_userNameKey, response.user.fullName);
    if (response.user.email != null) {
      await _writeStorage(_userEmailKey, response.user.email!);
    }
  }

  Future<String?> _readStorage(String key) async {
    try {
      final val = await _secureStorage.read(key: key);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      const fallback = FlutterSecureStorage();
      final val = await fallback.read(key: key);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    return null;
  }

  Future<void> _writeStorage(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {
      try {
        const fallback = FlutterSecureStorage();
        await fallback.write(key: key, value: value);
      } catch (_) {}
    }
  }

  Future<void> _deleteStorage(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {}
    try {
      const fallback = FlutterSecureStorage();
      await fallback.delete(key: key);
    } catch (_) {}
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
