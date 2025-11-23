import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';

import 'user_profile/user_profile_view.dart';
import 'company_profile/company_profile_view.dart';
import '../../core/providers/app_locale_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/button_sizes.dart';
import '../../data/models/app_user.dart';
import 'staff_management/staff_management_view.dart';

// Shared settings view that can be used by any shell.
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final Locale currentLocale = ref.watch(appLocaleProvider);
    final userProfile = ref.watch(userProfileProvider).asData?.value;
    final bool canManageStaff = userProfile != null &&
        (userProfile.role == UserRole.owner || userProfile.role == UserRole.manager);

    // Build the list of settings items displayed in the main scrollable area.
    final List<Widget> items = <Widget>[
      ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(l10n.settingsUserProfile),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const UserProfileView(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.business_outlined),
        title: Text(l10n.settingsCompanyProfile),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CompanyProfileView(),
            ),
          );
        },
      ),
      if (canManageStaff)
        ListTile(
          leading: const Icon(Icons.group_outlined),
          title: Text(l10n.settingsStaffManagement),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const StaffManagementView(),
              ),
            );
          },
        ),
      ListTile(
        leading: const Icon(Icons.language),
        title: Text(l10n.settingsLanguage),
        subtitle: Text(currentLocale.languageCode.toUpperCase()),
        trailing: const Icon(Icons.expand_more),
        onTap: () async {
          // TODO: Persist user's locale to backend when endpoint is available.
          await _showLocalePicker(context, ref, currentLocale);
        },
      ),
    ];

    // Wrap the settings list and the sign-out button in a column so that
    // the button remains pinned to the bottom of the screen.
    return SafeArea(
      child: Column(
        children: <Widget>[
          // Main scrollable settings content.
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) => items[index],
            ),
          ),

          // Sign-out button pinned to the bottom of the view.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                // Make the button match the height of other primary buttons (e.g. sign-in / sign-up).
                style: FilledButton.styleFrom(
                  minimumSize: ButtonSizes.mdFill,
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // Trigger sign-out via the authentication provider.
                  ref.read(authProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout),
                label: Text(
                  l10n.logout,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showLocalePicker(
  BuildContext context,
  WidgetRef ref,
  Locale currentLocale,
) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RadioListTile<Locale>(
              title: Text(AppLocalizations.of(context)!.settingsEnglish),
              value: const Locale('en'),
              groupValue: currentLocale,
              onChanged: (value) {
                if (value != null) {
                  ref.read(appLocaleProvider.notifier).setLocale(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<Locale>(
              title: Text(AppLocalizations.of(context)!.settingsRussian),
              value: const Locale('ru'),
              groupValue: currentLocale,
              onChanged: (value) {
                if (value != null) {
                  ref.read(appLocaleProvider.notifier).setLocale(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      );
    },
  );
}


