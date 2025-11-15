import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/auth_models.dart';

const String _accessTokenKey = 'access_token';
const String _refreshTokenKey = 'refresh_token';

AndroidOptions _androidOptions() =>
    const AndroidOptions(encryptedSharedPreferences: true);

IOSOptions _iosOptions() =>
    const IOSOptions(accessibility: KeychainAccessibility.first_unlock);

LinuxOptions _linuxOptions() => const LinuxOptions();

WebOptions _webOptions() => const WebOptions();

MacOsOptions _macOsOptions() => const MacOsOptions();

WindowsOptions _windowsOptions() => const WindowsOptions();

class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = kIsWeb
          ? null
          : storage ??
                FlutterSecureStorage(
                  aOptions: _androidOptions(),
                  iOptions: _iosOptions(),
                  lOptions: _linuxOptions(),
                  webOptions: _webOptions(),
                  mOptions: _macOsOptions(),
                  wOptions: _windowsOptions(),
                );

  final FlutterSecureStorage? _storage;
  final Map<String, String> _webCache = <String, String>{};

  Future<void> saveTokens(AuthTokens tokens) async {
    if (kIsWeb) {
      _webCache[_accessTokenKey] = tokens.accessToken;
      _webCache[_refreshTokenKey] = tokens.refreshToken;
      return;
    }

    final FlutterSecureStorage storage = _storage!;
    await storage.write(key: _accessTokenKey, value: tokens.accessToken);
    await storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
  }

  Future<AuthTokens?> readTokens() async {
    final String? access;
    final String? refresh;

    if (kIsWeb) {
      access = _webCache[_accessTokenKey];
      refresh = _webCache[_refreshTokenKey];
    } else {
      final FlutterSecureStorage storage = _storage!;
      access = await storage.read(key: _accessTokenKey);
      refresh = await storage.read(key: _refreshTokenKey);
    }

    if ((access == null || access.isEmpty) ||
        (refresh == null || refresh.isEmpty)) {
      return null;
    }

    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  Future<void> clearTokens() async {
    if (kIsWeb) {
      _webCache.clear();
      return;
    }

    final FlutterSecureStorage storage = _storage!;
    await storage.delete(key: _accessTokenKey);
    await storage.delete(key: _refreshTokenKey);
  }
}

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage();
});
