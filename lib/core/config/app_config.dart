import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Immutable configuration object that stores base URLs and other build-time flags.
@immutable
class AppConfig {
  const AppConfig({required this.apiRoot});

  final String apiRoot;

  // Build a configuration instance using compile-time environment values.
  factory AppConfig.fromEnvironment() {
    // Load the API root from --dart-define and fall back to a safe default.
    const String envApiRoot = String.fromEnvironment(
      'API_ROOT',
      defaultValue: _defaultApiRoot,
    );

    return AppConfig(apiRoot: envApiRoot);
  }

  // Default base URL used when no --dart-define override is supplied.
  static const String _defaultApiRoot = 'http://127.0.0.1:8000/';
}

// Riverpod provider that exposes the configuration to the rest of the app.
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});
