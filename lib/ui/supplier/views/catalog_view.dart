import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/company_profile_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../data/models/company.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import 'product_detail_view.dart';

// Supplier catalog page showing the current supplier's products.
class SupplierCatalogView extends ConsumerStatefulWidget {
  const SupplierCatalogView({super.key});

  @override
  ConsumerState<SupplierCatalogView> createState() => _SupplierCatalogViewState();
}

class _SupplierCatalogViewState extends ConsumerState<SupplierCatalogView> {
  // Controller to hold the search query (search not implemented by request).
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    // Dispose the controller to avoid memory leaks.
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read user and company state to ensure this page is supplier-only.
    final userState = ref.watch(userProfileProvider);
    final companyState = ref.watch(companyProfileProvider);

    // If we cannot determine the company yet, show loading indicators.
    if (userState.isLoading || companyState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // If user or company is missing, block access.
    final company = companyState.value;
    if (company == null) {
      return const Center(child: Text('Company not found.'));
    }

    // Enforce supplier-only access.
    if (company.companyType != CompanyType.supplier) {
      return const Center(child: Text('Catalog is available for suppliers only.'));
    }

    // Load products via repository.
    final productRepo = ref.watch(productRepositoryProvider);

    return FutureBuilder<List<Product>>(
      future: productRepo.listProducts(),
      builder: (context, snapshot) {
        // Basic loading and error states.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load catalog: ${snapshot.error}'));
        }

        final List<Product> products = snapshot.data ?? const <Product>[];

        return Scaffold(
          // Floating action button for creating a new product (not implemented).
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Creation UI intentionally not implemented as requested.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create product: not implemented yet')),
              );
            },
            child: const Icon(Icons.add),
          ),

          // Catalog content with a search field and the product list.
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Top search field - not wired to filtering yet per request.
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search (coming soon)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              // Expand to show the list of product cards.
              Expanded(
                child: products.isEmpty
                    ? const Center(child: Text('No products yet'))
                    : ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final Product product = products[index];

                          // Tap opens the product details page.
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ProductDetailView(product: product),
                                ),
                              );
                            },
                            child: _ProductCard(product: product),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Visual card that renders all product data fields at a glance.
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    // Build a clean, readable tile with key product attributes.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Pictures displayed above the title and description.
              if (product.pictureUrls.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: product.pictureUrls
                            .map(
                              (url) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 96,
                                    height: 96,
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // Product title in bold.
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: 4),

              // Description directly under the title.
              Text(
                product.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Retail price in bold primary color: "price₸ / unit".
              Text(
                '${product.retailPrice} ₸ / ${product.unit}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),

              const SizedBox(height: 4),

              // Stock information in smaller text right under the price.
              Text(
                'Stock: ${product.stockQuantity}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


