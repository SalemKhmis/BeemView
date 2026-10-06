import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Cubit managing the authentication lifecycle.
///
/// Responsibilities:
/// - Attempt session restore on app start.
/// - Login with email, password, and subdomain.
/// - Logout (clear token + user state, no server revocation).
/// - Handle 401 session expiry from the [AuthInterceptor].
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required this._authRepository})
      : super(const AuthInitial());

  /// Attempts to restore a previously persisted session on app start.
  ///
  /// Shows [AuthRestoring] while validating, then transitions to
  /// [AuthAuthenticated] or [AuthInitial] based on the result.
  Future<void> restoreSession() async {
    emit(const AuthRestoring());

    final user = await _authRepository.restoreSession();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthInitial());
    }
  }

  /// Authenticates the user with email, password, and subdomain.
  ///
  /// Validates inputs locally first, then calls the API.
  /// On success: emits [AuthAuthenticated].
  /// On failure: emits [AuthError] with a user-friendly message.
  Future<void> login({
    required String email,
    required String password,
    required String subdomain,
  }) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.login(
        email: email,
        password: password,
        subdomain: subdomain,
      );
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('An unexpected error occurred. Please try again.'));
    }
  }

  /// Clears the session and returns to the initial (login) state.
  ///
  /// Per the API contract, there is no server-side logout endpoint.
  /// This only clears the local token and user state.
  Future<void> logout() async {
    await _authRepository.clearSession();
    emit(const AuthInitial());
  }

  /// Called by the [AuthInterceptor] when a 401 is received.
  ///
  /// Clears the invalid session and emits [AuthSessionExpired]
  /// so the UI can show a specific "session expired" message
  /// and redirect to login.
  Future<void> onSessionExpired() async {
    await _authRepository.clearSession();
    if (!isClosed) {
      emit(const AuthSessionExpired());
    }
  }
}
