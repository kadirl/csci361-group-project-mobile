import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/authorized_dio_provider.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';

// Repository that exposes user profile operations.
class UserRepository {
  UserRepository(this._userService);

  final UserService _userService;

  /// Fetch the authenticated user profile.
  Future<AppUser> getCurrentUser() async {
    return _userService.fetchCurrentUser();
  }

  /// Fetch an arbitrary user profile by identifier.
  Future<AppUser> getUserById({required int userId}) async {
    return _userService.fetchUserById(userId: userId);
  }
}

// Provider that wires the user service with the authorized Dio instance.
final userServiceProvider = Provider<UserService>((ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  final dio = ref.watch(authorizedDioProvider);

  return UserService(config: config, dioClient: dio);
});

// Provider that exposes UserRepository to the rest of the app.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final UserService service = ref.watch(userServiceProvider);

  return UserRepository(service);
});

