/// API configuration for the BeemView backend.
///
/// Update [subdomain] with the tenant subdomain supplied by the hiring team.
/// The [origin] should remain as-is unless a different server is provided.
class ApiConfig {
  /// The base URL origin for the BeemView API.
  static const String origin = 'https://beemview.com';

  /// The tenant subdomain supplied by the hiring team.
  /// This is sent as part of the login request body.
  static const String subdomain = 'beemmobile';

  /// Full API base URL (origin + /api prefix).
  static String get baseUrl => '$origin/api';

  /// Default request timeout in milliseconds.
  static const int connectTimeoutMs = 15000;

  /// Default response timeout in milliseconds.
  static const int receiveTimeoutMs = 15000;

  /// Pagination defaults.
  static const int defaultPageLimit = 10;
  static const int defaultPageOffset = 0;
}
