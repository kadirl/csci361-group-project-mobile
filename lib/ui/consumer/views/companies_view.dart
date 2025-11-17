import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/company.dart';
import '../../../data/repositories/company_repository.dart';
import 'company_detail_view.dart';

// Provider to load all companies.
final companiesListProvider = FutureProvider<List<Company>>((ref) async {
  final repo = ref.read(companyRepositoryProvider);
  return repo.getAllCompanies();
});

// Consumer companies page showing available supplier companies.
class ConsumerCompaniesView extends ConsumerStatefulWidget {
  const ConsumerCompaniesView({super.key});

  @override
  ConsumerState<ConsumerCompaniesView> createState() => _ConsumerCompaniesViewState();
}

class _ConsumerCompaniesViewState extends ConsumerState<ConsumerCompaniesView> {
  // Controller to hold the search query.
  final TextEditingController _searchController = TextEditingController();

  // Current search query for filtering companies.
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Listen to search field changes to update filter.
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    // Dispose the controller to avoid memory leaks.
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Handle search field changes without triggering full rebuild.
  void _onSearchChanged() {
    final String newQuery = _searchController.text.toLowerCase().trim();
    if (newQuery != _searchQuery) {
      setState(() {
        _searchQuery = newQuery;
      });
    }
  }

  // Filter companies by name based on search query.
  List<Company> _filterCompanies(List<Company> companies, String query) {
    if (query.isEmpty) {
      return companies;
    }

    return companies
        .where(
          (Company company) =>
              company.name.toLowerCase().contains(query) ||
              (company.description?.toLowerCase().contains(query) ?? false) ||
              company.location.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesListProvider);

    return Scaffold(
      // Companies content with a search field and the company list.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Top search field for filtering companies by name, description, or location.
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                hintText: 'Search companies...',
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          // Expand to show the list of company cards.
          Expanded(
            child: companiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Error loading companies',
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
                          ref.invalidate(companiesListProvider);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (companies) {
                // Filter companies based on search query.
                final List<Company> filteredCompanies = _filterCompanies(companies, _searchQuery);

                if (companies.isEmpty) {
                  return const Center(child: Text('No companies yet'));
                }

                if (filteredCompanies.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No companies yet'
                          : 'No companies found matching "$_searchQuery"',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredCompanies.length,
                  itemBuilder: (context, index) {
                    final Company company = filteredCompanies[index];
                    return InkWell(
                      onTap: company.id != null
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => CompanyDetailView(companyId: company.id!),
                                ),
                              );
                            }
                          : null,
                      child: _CompanyCard(company: company),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Visual card that renders company data fields at a glance.
class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.company});

  final Company company;

  @override
  Widget build(BuildContext context) {
    // Build a clean, readable tile with key company attributes.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Company logo (with placeholder if not available).
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: company.logoUrl != null && company.logoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: Image.network(
                            company.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderLogo(),
                          ),
                        ),
                      )
                    : _buildPlaceholderLogo(),
              ),

              // Company name in bold.
              Text(
                company.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 4),

              // Location information.
              Row(
                children: <Widget>[
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    company.location,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Description if available.
              if (company.description != null)
                Text(
                  company.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Build placeholder logo with gray background and icon.
  Widget _buildPlaceholderLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.business,
        size: 32,
        color: Colors.grey,
      ),
    );
  }
}

