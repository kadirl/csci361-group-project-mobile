import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository(this._authService);

  final AuthService _authService;

  Future<SignUpResponse> registerCompany({required RegisterCompanyRequest request}) {
    return _authService.registerCompany(request: request);
  }

  Future<AuthTokens> login({required LoginRequest request}) {
    return _authService.login(request: request);
  }

  Future<AuthTokens> refreshToken({required String refreshToken}) {
    return _authService.refreshToken(refreshToken: refreshToken);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final appConfig = ref.watch(appConfigProvider);
  return AuthService(config: appConfig);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthRepository(authService);
});
