import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import '../../data/repositories/user_repository.dart';
import 'auth_provider.dart';

// Async notifier that loads and caches the authenticated user's profile.
class UserProfileNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    // Watch auth changes so we clear profile when user signs out.
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return null;
    }

    return _loadProfile();
  }

  // Explicitly reload the user profile from the backend.
  Future<void> refreshProfile() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(_loadProfile);
  }

  Future<AppUser> _loadProfile() async {
    final repository = ref.read(userRepositoryProvider);

    log('UserProfileNotifier -> fetching current user profile');

    return repository.getCurrentUser();
  }
}

// Provider that exposes UserProfileNotifier state to the UI.
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, AppUser?>(
      UserProfileNotifier.new,
    );

