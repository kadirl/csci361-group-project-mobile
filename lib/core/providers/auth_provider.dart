import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../storage/secure_token_storage.dart';

// User model to store logged-in user data
class User {
  final String email;
  final String? name;

  const User({required this.email, this.name});
}

// Authentication state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final String? accessToken;
  final String? refreshToken;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.accessToken,
    this.refreshToken,
  });

  // Check if user is authenticated
  bool get isAuthenticated => user != null;

  // CopyWith method for immutability
  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}

// Authentication notifier - manages login state
class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _authRepository = ref.read(authRepositoryProvider);
  late final SecureTokenStorage _tokenStorage = ref.read(
    secureTokenStorageProvider,
  );

  @override
  AuthState build() {
    // Attempt to restore persisted tokens on startup.
    _restorePersistedTokens();

    return const AuthState();
  }

  Future<void> _restorePersistedTokens() async {
    final AuthTokens? tokens = await _tokenStorage.readTokens();

    if (tokens != null) {
      state = state.copyWith(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    }
  }

  // Sign in using remote API
  Future<void> signIn({required String email, required String password}) async {
    // Set loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      final AuthTokens tokens = await _authRepository.login(
        request: LoginRequest(email: email, password: password),
      );

      await _tokenStorage.saveTokens(tokens);

      final User user = User(email: email, name: email.split('@').first);

      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    } catch (e) {
      // Set error state
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Sign up method
  Future<void> signUp({required RegisterCompanyRequest request}) async {
    // Set loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.registerCompany(request: request);

      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Refresh the active session using the stored refresh token.
  Future<void> refreshSession() async {
    final String? existingRefreshToken = state.refreshToken;
    String? tokenToUse = existingRefreshToken;

    tokenToUse ??= (await _tokenStorage.readTokens())?.refreshToken;

    if (tokenToUse == null || tokenToUse.isEmpty) {
      return;
    }

    try {
      final AuthTokens tokens = await _authRepository.refreshToken(
        refreshToken: tokenToUse,
      );

      await _tokenStorage.saveTokens(tokens);

      state = state.copyWith(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Sign out method
  Future<void> signOut() async {
    await _tokenStorage.clearTokens();
    state = const AuthState();
  }
}

// Provider instance
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
