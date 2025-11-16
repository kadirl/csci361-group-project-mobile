import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/company_profile_provider.dart';
import '../../../../core/providers/user_profile_provider.dart';
import '../../../../data/models/company.dart';
import '../../../../data/models/product.dart';
import '../../../../data/models/app_user.dart';
import '../../../../data/repositories/product_repository.dart';
import 'product/product_detail_view.dart';
import 'product/create_product_view.dart';

// Supplier catalog page showing the current supplier's products.
class SupplierCatalogView extends ConsumerStatefulWidget {
  const SupplierCatalogView({super.key});

  @override
  ConsumerState<SupplierCatalogView> createState() => _SupplierCatalogViewState();
}

class _SupplierCatalogViewState extends ConsumerState<SupplierCatalogView> {
  // Controller to hold the search query.
  final TextEditingController _searchController = TextEditingController();

  // Current search query for filtering products.
  String _searchQuery = '';

  // Cache the loaded products to avoid reloading on every rebuild.
  List<Product>? _cachedProducts;
  bool _isLoadingProducts = false;
  String? _productsError;

  @override
  void initState() {
    super.initState();

    // Listen to search field changes to update filter (no setState needed).
    _searchController.addListener(_onSearchChanged);

    // Load products once when widget initializes.
    _loadProducts();
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

  // Load products once and cache them.
  Future<void> _loadProducts() async {
    final userState = ref.read(userProfileProvider);
    final appUser = userState.value;

    if (appUser?.companyId == null) {
      return;
    }

    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });

    try {
      final productRepo = ref.read(productRepositoryProvider);
      final products = await productRepo.listProducts(companyId: appUser!.companyId!);

      if (mounted) {
        setState(() {
          _cachedProducts = products;
          _isLoadingProducts = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _productsError = error.toString();
          _isLoadingProducts = false;
        });
      }
    }
  }

  // Filter products by name based on search query.
  List<Product> _filterProducts(List<Product> products, String query) {
    if (query.isEmpty) {
      return products;
    }

    return products
        .where(
          (Product product) =>
              product.name.toLowerCase().contains(query),
        )
        .toList();
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

    // Get user profile which contains company_id.
    final appUser = userState.value;
    if (appUser == null || appUser.companyId == null) {
      return const Center(child: Text('User profile or company ID not found.'));
    }

    // If company is missing, block access.
    final company = companyState.value;
    if (company == null) {
      return const Center(child: Text('Company not found.'));
    }

    // Enforce supplier-only access.
    if (company.companyType != CompanyType.supplier) {
      return const Center(child: Text('Catalog is available for suppliers only.'));
    }

    // Show loading state while products are being loaded.
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state if products failed to load.
    if (_productsError != null) {
      return Center(child: Text('Failed to load catalog: $_productsError'));
    }

    // Get cached products or empty list.
    final List<Product> allProducts = _cachedProducts ?? const <Product>[];

    // Filter products based on search query.
    final List<Product> filteredProducts = _filterProducts(allProducts, _searchQuery);

    // Determine whether current user can manage products.
    final bool canManageProducts = appUser.role == UserRole.owner || appUser.role == UserRole.manager;

    return Scaffold(
      // Floating action button for creating a new product.
      floatingActionButton: canManageProducts
          ? FloatingActionButton(
              onPressed: () async {
                // Navigate to full-screen create product page.
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateProductView(),
                  ),
                );
                // Reload products after returning from create view.
                _loadProducts();
              },
              child: const Icon(Icons.add),
            )
          : null,

      // Catalog content with a search field and the product list.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Top search field for filtering products by name.
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
                hintText: 'Search products...',
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          // Expand to show the list of product cards.
          Expanded(
            child: allProducts.isEmpty
                ? const Center(child: Text('No products yet'))
                : filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No products yet'
                              : 'No products found matching "$_searchQuery"',
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final Product product = filteredProducts[index];

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


