import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/company.dart';
import '../../../data/repositories/company_repository.dart';

// Provider to load a single company by ID.
final companyByIdProvider = FutureProvider.family<Company, int>((ref, companyId) async {
  final repo = ref.read(companyRepositoryProvider);
  try {
    final company = await repo.getCompany(companyId: companyId, forceRefresh: true);
    return company;
  } catch (e) {
    rethrow;
  }
});

// Company detail page showing full company information.
class CompanyDetailView extends ConsumerWidget {
  const CompanyDetailView({
    super.key,
    required this.companyId,
  });

  final int companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyByIdProvider(companyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Details'),
      ),
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Failed to fetch',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(companyByIdProvider(companyId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (company) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Company logo (with placeholder if not available).
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: company.logoUrl != null && company.logoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 128,
                            height: 128,
                            child: Image.network(
                              company.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholderLogo(128),
                            ),
                          ),
                        )
                      : _buildPlaceholderLogo(128),
                ),
              ),

              const SizedBox(height: 16),

              // Company name in bold.
              Text(
                company.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 16),

              // Location information.
              Row(
                children: <Widget>[
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      company.location,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description if available.
              if (company.description != null && company.description!.isNotEmpty) ...[
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  company.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}

// Build placeholder logo with gray background and icon.
Widget _buildPlaceholderLogo(double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(
      Icons.business,
      size: size / 2,
      color: Colors.grey,
    ),
  );
}

