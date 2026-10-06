import 'package:equatable/equatable.dart';

import '../../models/user.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  final User? cachedUser;

  const ProfileLoading({this.cachedUser});

  @override
  List<Object?> get props => [cachedUser];
}

class ProfileLoaded extends ProfileState {
  final User user;

  const ProfileLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;
  final User? cachedUser;

  const ProfileError({
    required this.message,
    this.cachedUser,
  });

  @override
  List<Object?> get props => [message, cachedUser];
}
