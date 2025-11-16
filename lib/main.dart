import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';
import 'package:swe_mobile/core/providers/auth_provider.dart';
import 'package:swe_mobile/ui/auth/login/login_view.dart';
import 'package:swe_mobile/ui/supplier/supplier_shell.dart';
import 'package:swe_mobile/ui/consumer/consumer_shell.dart';
import 'package:swe_mobile/core/providers/user_profile_provider.dart';
import 'package:swe_mobile/core/providers/company_profile_provider.dart';
import 'package:swe_mobile/data/models/company.dart';
import 'package:swe_mobile/core/providers/app_locale_provider.dart';

void main() {
  runApp(
    // Wrap app with ProviderScope for Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observe app locale to support runtime changes.
    final Locale currentLocale = ref.watch(appLocaleProvider);

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
      // Use app-level locale so it can be changed at runtime.
      locale: currentLocale,
      
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
    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      data: (user) {
        if (user == null) {
          // If user profile cannot be resolved, sign out defensively
          ref.read(authProvider.notifier).signOut();
          return const LoginScreen();
        }

        final companyProfileAsync = ref.watch(companyProfileProvider);

        return companyProfileAsync.when(
          data: (company) {
            if (company?.companyType == CompanyType.consumer) {
              return const ConsumerShell();
            }

            return const SupplierShell();
          },
          loading: () => _buildSplashLoader(),
          error: (_, __) {
            // Company failed to load (e.g., company deleted) -> sign out
            ref.read(authProvider.notifier).signOut();
            return const LoginScreen();
          },
        );
      },
      loading: () => _buildSplashLoader(),
      error: (_, __) {
        // User failed to load (e.g., user deleted) -> sign out
        ref.read(authProvider.notifier).signOut();
        return const LoginScreen();
      },
    );
  }

  Widget _buildSplashLoader() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
