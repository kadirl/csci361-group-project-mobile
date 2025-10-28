import 'package:flutter/material.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';
import '../widgets/login_form_widget.dart';

// Login screen
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get localized strings
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo or icon
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),

                const SizedBox(height: 24),

                // Welcome text
                Text(
                  l10n.welcome,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

                Text(
                  l10n.signInToContinue,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),

                const SizedBox(height: 48),

                // Login form
                const LoginFormWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

