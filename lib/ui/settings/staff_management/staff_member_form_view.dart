import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';
import 'package:swe_mobile/core/constants/button_sizes.dart';

import '../../../core/providers/user_profile_provider.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/user_create.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/signup/signup_viewmodel.dart';

class StaffMemberFormView extends ConsumerStatefulWidget {
  const StaffMemberFormView({super.key});

  @override
  ConsumerState<StaffMemberFormView> createState() =>
      _StaffMemberFormViewState();
}

class _StaffMemberFormViewState extends ConsumerState<StaffMemberFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  UserRole? _selectedRole;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(userProfileProvider).asData?.value;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<UserRole> allowedRoles = _allowedRolesFor(currentUser.role);

    _selectedRole ??= allowedRoles.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.staffManagementTitle),
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
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    hintText: l10n.passwordPlaceholder,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => SignupValidators.validateRequiredField(
                    value,
                    l10n.password,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  items: allowedRoles
                      .map(
                        (role) => DropdownMenuItem<UserRole>(
                          value: role,
                          child: Text(role.name),
                        ),
                      )
                      .toList(),
                  decoration: InputDecoration(
                    labelText: l10n.userRole,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _selectedRole = value);
                  },
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

  List<UserRole> _allowedRolesFor(UserRole current) {
    switch (current) {
      case UserRole.owner:
        return const <UserRole>[UserRole.manager, UserRole.staff];
      case UserRole.manager:
        return const <UserRole>[UserRole.staff];
      case UserRole.staff:
        return const <UserRole>[];
    }
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = ref.read(userProfileProvider).asData?.value;
    if (currentUser == null || _selectedRole == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    final String digitsOnly =
        _phoneCtrl.text.replaceAll(RegExp(r'\\D'), '');

    final UserCreateRequest request = UserCreateRequest(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phoneNumber: digitsOnly,
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _selectedRole!.name, // owner/manager/staff literal
      locale: currentUser.locale,
    );

    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.addUser(request: request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.staffCreateUserSuccess),
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
                child: const Text('OK'),
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


