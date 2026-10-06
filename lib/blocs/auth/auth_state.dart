import 'package:equatable/equatable.dart';

import '../../models/user.dart';

/// States for the authentication flow.
///
/// Flow: AuthInitial → AuthLoading → Authenticated | AuthError
///       Authenticated → AuthInitial (on logout)
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no session check has been performed yet.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Checking credentials or restoring a session.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Session restore is in progress (shown on app start).
/// Distinguished from [AuthLoading] so the UI can show a splash
/// screen instead of the login form.
class AuthRestoring extends AuthState {
  const AuthRestoring();
}

/// Successfully authenticated with a valid token and user profile.
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Authentication failed with an error message.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Session expired (401 received from a protected request).
/// Distinct from [AuthError] so the UI can show a specific message.
class AuthSessionExpired extends AuthState {
  const AuthSessionExpired();
}
