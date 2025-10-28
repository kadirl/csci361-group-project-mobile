import 'package:flutter_riverpod/flutter_riverpod.dart';

// User model to store logged-in user data
class User {
  final String email;
  final String? name;

  const User({
    required this.email,
    this.name,
  });
}

// Authentication state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  // Check if user is authenticated
  bool get isAuthenticated => user != null;

  // CopyWith method for immutability
  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Authentication notifier - manages login state
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Initialize with empty state
    return const AuthState();
  }

  // Sign in method with placeholder authentication
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    // Set loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Placeholder validation (accepts any non-empty email/password)
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      // Create user object (placeholder - will be replaced with API response)
      final user = User(
        email: email,
        name: email.split('@').first, // Extract name from email
      );

      // Update state with logged-in user
      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      // Set error state
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Sign up method (placeholder)
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    // Set loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Placeholder validation
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      // For now, sign up just signs in (placeholder implementation)
      await signIn(email: email, password: password);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Sign out method
  void signOut() {
    state = const AuthState();
  }
}

// Provider instance
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
