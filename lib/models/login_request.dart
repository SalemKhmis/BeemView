/// Login request data transfer object.
///
/// Sent as JSON body to `POST /api/auth/login`.
/// All three fields are required by the API contract.
class LoginRequest {
  final String email;
  final String password;
  final String subdomain;

  const LoginRequest({
    required this.email,
    required this.password,
    required this.subdomain,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'subdomain': subdomain,
    };
  }
}
