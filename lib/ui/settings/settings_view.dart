import 'package:flutter/material.dart';

import 'user_profile/user_profile_view.dart';
import 'company_profile/company_profile_view.dart';

// Shared settings view that can be used by any shell.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 2,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('User profile'),
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
          default:
            return ListTile(
              leading: const Icon(Icons.business_outlined),
              title: const Text('Company profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CompanyProfileView(),
                  ),
                );
              },
            );
        }
      },
    );
  }
}


