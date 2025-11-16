import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider that holds the current app locale and allows changing it locally.
class AppLocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // Default to English, then try to restore persisted locale asynchronously.
    _restorePersistedLocale();
    return const Locale('en');
  }

  void setLocale(Locale locale) {
    state = locale;
    _persistLocale(locale);
  }

  static const String _prefsKey = 'app_locale';

  Future<void> _restorePersistedLocale() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? code = prefs.getString(_prefsKey);
      if (code != null && code.isNotEmpty) {
        state = Locale(code);
      }
    } catch (_) {
      // Ignore persistence errors silently; fallback to default.
    }
  }

  Future<void> _persistLocale(Locale locale) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, locale.languageCode);
    } catch (_) {
      // Ignore persistence errors for now.
    }
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(
  AppLocaleNotifier.new,
);


