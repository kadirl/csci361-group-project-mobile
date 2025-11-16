import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';

import '../../../core/providers/company_profile_provider.dart';
import '../../../data/models/company.dart';

// Displays current company profile information using companyProfileProvider.
class CompanyProfileView extends ConsumerWidget {
  const CompanyProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final companyAsync = ref.watch(companyProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.companyProfileTitle)),
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: l10n.errorLoadingCompany,
          onRetry: () =>
              ref.read(companyProfileProvider.notifier).refreshCompany(),
        ),
        data: (company) {
          if (company == null) {
            return _ErrorState(
              message: l10n.noCompanyProfile,
              onRetry: () =>
                  ref.read(companyProfileProvider.notifier).refreshCompany(),
            );
          }

          return ListView(
            children: <Widget>[
              _InfoTile(label: l10n.companyName, value: company.name),
              _InfoTile(label: l10n.companyLocation, value: company.location),
              _InfoTile(
                label: l10n.companyType,
                value: _formatType(context, company.companyType),
              ),
              _InfoTile(
                label: l10n.companyDescription,
                value: company.description ?? '—',
              ),
              if (company.id != null)
                _InfoTile(label: l10n.companyId, value: '${company.id}'),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(l10n.refreshCompany),
                onTap: () =>
                    ref.read(companyProfileProvider.notifier).refreshCompany(),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatType(BuildContext context, CompanyType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case CompanyType.supplier:
        return l10n.companyTypeSupplier;
      case CompanyType.consumer:
        return l10n.companyTypeConsumer;
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.errorLoadingCompany,
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


