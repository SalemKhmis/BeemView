import 'package:dio/dio.dart';

import '../../config/api_config.dart';
import 'auth_interceptor.dart';

/// Central HTTP client for all BeemView API requests.
///
/// Configures Dio with:
/// - Base URL from [ApiConfig]
/// - Content-Type and Accept-Language headers
/// - Connection and receive timeouts
/// - [AuthInterceptor] for automatic Bearer token injection and 401 handling
///
/// Usage:
/// ```dart
/// final client = ApiClient(
///   tokenProvider: () => secureStorage.read(key: 'token'),
///   onSessionExpired: () => navigateToLogin(),
/// );
/// ```
class ApiClient {
  late final Dio dio;

  /// Creates an [ApiClient] with the configured interceptors.
  ///
  /// [tokenProvider] returns the current auth token (or null if not logged in).
  /// [onSessionExpired] is called when a 401 is received, signaling that the
  /// stored token is invalid and the user must re-authenticate.
  ApiClient({
    required Future<String?> Function() tokenProvider,
    required void Function() onSessionExpired,
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept-Language': 'en',
        },
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(
        tokenProvider: tokenProvider,
        onSessionExpired: onSessionExpired,
      ),
    );
  }
}
