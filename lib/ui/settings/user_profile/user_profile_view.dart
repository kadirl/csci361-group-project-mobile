import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/user_profile_provider.dart';
import '../../../core/providers/company_profile_provider.dart';

// Displays current user's profile information using user & company providers.
class UserProfileView extends ConsumerWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final companyAsync = ref.watch(companyProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('User profile')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () =>
              ref.read(userProfileProvider.notifier).refreshProfile(),
        ),
        data: (user) {
          if (user == null) {
            return _ErrorState(
              message: 'No user profile available',
              onRetry: () =>
                  ref.read(userProfileProvider.notifier).refreshProfile(),
            );
          }

          return ListView(
            children: <Widget>[
              _InfoTile(label: 'First name', value: user.firstName),
              _InfoTile(label: 'Last name', value: user.lastName),
              _InfoTile(label: 'Email', value: user.email),
              _InfoTile(label: 'Phone number', value: user.phoneNumber),
              _InfoTile(label: 'Role', value: user.role),
              _InfoTile(label: 'Locale', value: user.locale),
              companyAsync.when(
                loading: () => const ListTile(
                  title: Text('Company'),
                  subtitle: Text('Loading...'),
                ),
                error: (_, __) => const ListTile(
                  title: Text('Company'),
                  subtitle: Text('—'),
                ),
                data: (company) => _InfoTile(
                  label: 'Company',
                  value: company?.name ?? '—',
                ),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh profile'),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Failed to load profile',
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
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}


