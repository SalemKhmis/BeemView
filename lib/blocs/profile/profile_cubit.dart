import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import 'profile_state.dart';

/// Cubit managing the current user profile data from `GET /api/users/me/profile`.
class ProfileCubit extends Cubit<ProfileState> {
  final AuthRepository authRepository;

  ProfileCubit({required this.authRepository}) : super(const ProfileInitial()) {
    // If the auth repository already has a cached user, initialize with it
    if (authRepository.currentUser != null) {
      emit(ProfileLoaded(authRepository.currentUser!));
    }
  }

  /// Loads or refreshes the user profile from `/api/users/me/profile`.
  Future<void> loadProfile({bool isRefresh = false}) async {
    final currentUser = authRepository.currentUser;

    if (!isRefresh && state is! ProfileLoaded) {
      emit(ProfileLoading(cachedUser: currentUser));
    }

    try {
      final freshUser = await authRepository.getProfile();
      emit(ProfileLoaded(freshUser));
    } on AuthException catch (e) {
      emit(ProfileError(
        message: e.message,
        cachedUser: currentUser,
      ));
    } catch (e) {
      emit(ProfileError(
        message: 'Unable to load profile. Please check your connection.',
        cachedUser: currentUser,
      ));
    }
  }
}
