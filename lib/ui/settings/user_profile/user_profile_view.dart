import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';

import '../../../core/providers/user_profile_provider.dart';
import '../../../core/providers/company_profile_provider.dart';
import 'user_edit_form_view.dart';

// Displays current user's profile information using user & company providers.
class UserProfileView extends ConsumerWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(userProfileProvider);
    final companyAsync = ref.watch(companyProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.userProfileTitle),
        actions: <Widget>[
          // Edit button - only show if user is viewing their own profile
          Builder(
            builder: (context) {
              final currentUser = userAsync.asData?.value;
              if (currentUser == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => UserEditFormView(user: currentUser),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: l10n.errorLoadingProfile,
          onRetry: () =>
              ref.read(userProfileProvider.notifier).refreshProfile(),
        ),
        data: (user) {
          if (user == null) {
            return _ErrorState(
              message: l10n.noUserProfile,
              onRetry: () =>
                  ref.read(userProfileProvider.notifier).refreshProfile(),
            );
          }

          return ListView(
            children: <Widget>[
              _InfoTile(label: l10n.firstName, value: user.firstName),
              _InfoTile(label: l10n.lastName, value: user.lastName),
              _InfoTile(label: l10n.email, value: user.email),
              _InfoTile(label: l10n.phoneNumber, value: user.phoneNumber),
              // Display enum role as its name.
              _InfoTile(label: l10n.userRole, value: user.role.name),
              _InfoTile(label: l10n.userLocale, value: user.locale),
              companyAsync.when(
                loading: () => ListTile(
                  title: Text(l10n.companyLabel),
                  subtitle: Text(l10n.commonLoading),
                ),
                error: (_, __) => ListTile(
                  title: Text(l10n.companyLabel),
                  subtitle: const Text('—'),
                ),
                data: (company) => _InfoTile(
                  label: l10n.companyLabel,
                  value: company?.name ?? '—',
                ),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(l10n.refreshProfile),
                onTap: () =>
                    ref.read(userProfileProvider.notifier).refreshProfile(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value.isEmpty ? '—' : value),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.errorLoadingProfile,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}


