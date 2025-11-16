import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/company_profile_provider.dart';
import '../../../data/models/company.dart';

// Displays current company profile information using companyProfileProvider.
class CompanyProfileView extends ConsumerWidget {
  const CompanyProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Company profile')),
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () =>
              ref.read(companyProfileProvider.notifier).refreshCompany(),
        ),
        data: (company) {
          if (company == null) {
            return _ErrorState(
              message: 'No company profile available',
              onRetry: () =>
                  ref.read(companyProfileProvider.notifier).refreshCompany(),
            );
          }

          return ListView(
            children: <Widget>[
              _InfoTile(label: 'Name', value: company.name),
              _InfoTile(label: 'Location', value: company.location),
              _InfoTile(
                label: 'Type',
                value: _formatType(company.companyType),
              ),
              _InfoTile(
                label: 'Description',
                value: company.description ?? '—',
              ),
              if (company.id != null)
                _InfoTile(label: 'Company ID', value: '${company.id}'),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh company'),
                onTap: () =>
                    ref.read(companyProfileProvider.notifier).refreshCompany(),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatType(CompanyType type) {
    switch (type) {
      case CompanyType.supplier:
        return 'Supplier';
      case CompanyType.consumer:
        return 'Consumer';
    }
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
              'Failed to load company',
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


