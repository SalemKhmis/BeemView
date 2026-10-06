/// Input validation helpers for login form fields.
///
/// Validation rules come from the API contract:
/// - Email must be valid format
/// - Password must contain at least 6 characters
/// - Subdomain must be nonempty
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Returns an error message if [email] is invalid, or null if valid.
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Returns an error message if [password] is invalid, or null if valid.
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Returns an error message if [subdomain] is invalid, or null if valid.
  static String? validateSubdomain(String? subdomain) {
    if (subdomain == null || subdomain.trim().isEmpty) {
      return 'Subdomain is required';
    }
    return null;
  }
}
