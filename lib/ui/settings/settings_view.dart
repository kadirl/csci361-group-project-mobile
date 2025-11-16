import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';

import 'user_profile/user_profile_view.dart';
import 'company_profile/company_profile_view.dart';
import '../../core/providers/app_locale_provider.dart';

// Shared settings view that can be used by any shell.
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final Locale currentLocale = ref.watch(appLocaleProvider);

    return ListView.separated(
      itemCount: 3,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return ListTile(
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
            );
          case 1:
            return ListTile(
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
            );
          case 2:
          default:
            return ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.settingsLanguage),
              subtitle: Text(currentLocale.languageCode.toUpperCase()),
              trailing: const Icon(Icons.expand_more),
              onTap: () async {
                // TODO: Persist user's locale to backend when endpoint is available.
                await _showLocalePicker(context, ref, currentLocale);
              },
            );
        }
      },
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
              title: const Text('English'),
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
              title: const Text('Русский'),
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


