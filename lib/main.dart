import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/main_screen/screens/main_screen.dart';

void main() {
  runApp(
    // Wrap app with ProviderScope for Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SWE Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      
      // Localization support
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('ru', ''), // Russian
      ],
      // Set default locale (defaults to system locale if not specified)
      locale: const Locale('ru'), // Change 'ru' to 'en' for English
      
      // Use Consumer to watch auth state and navigate accordinlgy
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Wrapper widget that checks auth state and displays appropriate screen
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch authentication state
    final authState = ref.watch(authProvider);

    // Show login screen if not authenticated
    // Show main screen if authenticated
    return authState.isAuthenticated
        ? const MainScreen()
        : const LoginScreen();
  }
}
