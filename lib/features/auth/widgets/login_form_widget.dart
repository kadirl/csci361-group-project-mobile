import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/button_sizes.dart';

// Login form widget
class LoginFormWidget extends ConsumerStatefulWidget {
  const LoginFormWidget({super.key, this.onSignUpPressed});
  final VoidCallback? onSignUpPressed;

  @override
  ConsumerState<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends ConsumerState<LoginFormWidget> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Password visibility toggle
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    // Clean up controllers
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle sign in button press
  Future<void> _handleSignIn() async {
    // Validate form
    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state for errors
    final authState = ref.watch(authProvider);

    // Watch isLoading state
    final isLoading = authState.isLoading;

    // Get localized strings
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.email,
                hintText: l10n.emailPlaceholder,
                prefixIcon: const Icon(Icons.email),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.emailRequired;
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Password field with visibility toggle
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: l10n.password,
                hintText: l10n.passwordPlaceholder,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.passwordRequired;
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Error message display
            if (authState.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  authState.error!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),

            if (authState.error != null) const SizedBox(height: 16),

            // Sign in button
            FilledButton(
              onPressed: isLoading ? null : _handleSignIn,
              style: FilledButton.styleFrom(
                minimumSize: ButtonSizes.mdFill,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.signIn,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),

            const SizedBox(height: 12),

            // Sign up button
            FilledButton.tonal(
              onPressed: isLoading ? null : widget.onSignUpPressed,
              style: FilledButton.styleFrom(
                minimumSize: ButtonSizes.mdFill,
              ),
              child: Text(
                l10n.signUp,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

