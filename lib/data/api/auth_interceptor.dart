import 'package:dio/dio.dart';

/// Dio interceptor that handles authentication concerns.
///
/// **Token injection:** Attaches `Authorization: Bearer <token>` to every
/// request if a token is available from [tokenProvider].
///
/// **401 handling:** When a protected request receives HTTP 401 (missing,
/// invalid, or expired token), the interceptor calls [onSessionExpired]
/// to clear the session and return the user to login.
///
/// **403 distinction:** HTTP 403 (insufficient access / inactive account)
/// is intentionally NOT treated as session expiry. It is passed through
/// as a normal error for the UI layer to handle with a specific message.
class AuthInterceptor extends Interceptor {
  final Future<String?> Function() tokenProvider;
  final void Function() onSessionExpired;

  AuthInterceptor({
    required this.tokenProvider,
    required this.onSessionExpired,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token is invalid or expired — clear session and redirect to login.
      // Do NOT treat 403 the same way; 403 means insufficient permissions,
      // not an expired session.
      onSessionExpired();
    }
    // Always forward the error so the calling code can handle it too.
    handler.next(err);
  }
}
