import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';
import 'package:swe_mobile/core/constants/button_sizes.dart';

import '../../../core/providers/user_profile_provider.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/user_update.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/signup/signup_viewmodel.dart';

class UserEditFormView extends ConsumerStatefulWidget {
  const UserEditFormView({required this.user, super.key});

  final AppUser user;

  @override
  ConsumerState<UserEditFormView> createState() => _UserEditFormViewState();
}

class _UserEditFormViewState extends ConsumerState<UserEditFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers with current user data
    _firstNameCtrl = TextEditingController(text: widget.user.firstName);
    _lastNameCtrl = TextEditingController(text: widget.user.lastName);
    // Format phone number for display
    _phoneCtrl = TextEditingController(
      text: _formatPhoneNumber(widget.user.phoneNumber),
    );
    _emailCtrl = TextEditingController(text: widget.user.email);
  }

  // Format phone number for display (e.g., "77077077777" -> "+7 707 707 7777")
  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return '';
    
    // Extract digits only
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    // If already formatted (contains + or spaces), return as is
    if (phoneNumber.contains('+') || phoneNumber.contains(' ')) {
      return phoneNumber;
    }
    
    // Ensure it starts with 7
    if (!digitsOnly.startsWith('7')) {
      if (digitsOnly.isNotEmpty) {
        digitsOnly = '7$digitsOnly';
      } else {
        return '';
      }
    }
    
    // Limit to 11 digits
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }
    
    // Format: +7 XXX XXX XXXX
    if (digitsOnly.length <= 1) {
      return '+7';
    }
    
    final String localDigits = digitsOnly.substring(1);
    final StringBuffer formatted = StringBuffer('+7');
    
    if (localDigits.isNotEmpty) {
      formatted.write(' ');
      formatted.write(localDigits.substring(0, localDigits.length > 3 ? 3 : localDigits.length));
    }
    
    if (localDigits.length > 3) {
      formatted.write(' ');
      formatted.write(localDigits.substring(3, localDigits.length > 6 ? 6 : localDigits.length));
    }
    
    if (localDigits.length > 6) {
      formatted.write(' ');
      formatted.write(localDigits.substring(6));
    }
    
    return formatted.toString();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.userProfileTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUnfocus,
            child: ListView(
              children: <Widget>[
                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.firstName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => SignupValidators.validateRequiredField(
                    value,
                    l10n.firstName,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.lastName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => SignupValidators.validateRequiredField(
                    value,
                    l10n.lastName,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: const <TextInputFormatter>[
                    PhoneNumberFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumber,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => SignupValidators.validatePhoneNumber(
                    value,
                    l10n.phoneNumber,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    hintText: l10n.emailPlaceholder,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => SignupValidators.validateEmail(
                    value,
                    l10n.email,
                  ),
                ),
                const SizedBox(height: 12),
                // Role field - read-only
                TextFormField(
                  initialValue: widget.user.role.name,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: l10n.userRole,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Locale field - read-only
                TextFormField(
                  initialValue: widget.user.locale.isEmpty
                      ? '—'
                      : widget.user.locale,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: l10n.userLocale,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : () => _submit(l10n),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(l10n.commonSubmit),
                  style: FilledButton.styleFrom(
                    minimumSize: ButtonSizes.mdFill,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.user.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.userEditUserIdMissing),
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    final String digitsOnly =
        _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');

    final UserUpdateRequest request = UserUpdateRequest(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phoneNumber: digitsOnly,
      email: _emailCtrl.text.trim(),
    );

    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateUser(userId: widget.user.id!, request: request);

      // Refresh the user profile
      ref.read(userProfileProvider.notifier).refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.userEditProfileUpdatedSuccess),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.errorLoadingProfile),
            content: Text(e.toString()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.commonOK),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

