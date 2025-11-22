import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/constants/button_sizes.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/company.dart';
import '../../../data/models/linking.dart';
import '../../../data/models/order.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/company_repository.dart';
import '../../../data/repositories/linking_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../supplier/views/catalog/product/product_detail_view.dart';
import 'company_detail_view.dart';

// Provider to load products that are in the cart
// Takes cart items as a family parameter to avoid watching cartProvider directly
final cartProductsProvider = FutureProvider.autoDispose
    .family<Map<int, Product>, List<CartItem>>((ref, cartItems) async {
  final productRepo = ref.read(productRepositoryProvider);
  final companyRepo = ref.read(companyRepositoryProvider);

  // If cart is empty, return empty map
  if (cartItems.isEmpty) {
    return {};
  }

  try {
    // Get cart product IDs first
    final cartProductIds = cartItems.map((item) => item.productId).toSet();
    
    // Get all companies
    final companies = await companyRepo.getAllCompanies();
    
    // Filter to only supplier companies (consumers don't have products)
    final supplierCompanies = companies.where(
      (company) => company.companyType == CompanyType.supplier && company.id != null,
    ).toList();
    
    // Create a map to store products by productId
    final productMap = <int, Product>{};
    
    // Fetch products from supplier companies only
    // Stop early if we've found all products we need
    for (final company in supplierCompanies) {
      if (company.id == null) {
        continue;
      }
      
      // Check if we've found all products we need
      final foundProductIds = productMap.keys.toSet();
      final neededProductIds = cartProductIds.difference(foundProductIds);
      if (neededProductIds.isEmpty) {
        break; // Found all products, no need to continue
      }
      
      try {
        final products = await productRepo.listProducts(companyId: company.id!);
        for (final product in products) {
          if (product.id != null && cartProductIds.contains(product.id)) {
            productMap[product.id!] = product;
          }
        }
      } catch (e) {
        // Skip companies that fail to load products
        continue;
      }
    }
    
    return productMap;
  } catch (e) {
    rethrow;
  }
});

// Helper class to represent a cart item with its product and company info
class CartItemWithProduct {
  const CartItemWithProduct({
    required this.cartItem,
    required this.product,
    required this.company,
  });

  final CartItem cartItem;
  final Product product;
  final Company company;
}

// Helper class to represent products grouped by company
class CompanyCartGroup {
  const CompanyCartGroup({
    required this.company,
    required this.items,
  });

  final Company company;
  final List<CartItemWithProduct> items;

  // Calculate total price for this company's cart items
  int get totalPrice {
    return items.fold(0, (sum, item) {
      return sum + (item.product.retailPrice * item.cartItem.count);
    });
  }
}

// Cart view displaying products grouped by supplier company
class ConsumerCartView extends ConsumerWidget {
  const ConsumerCartView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    // Show loading state while cart is loading
    if (cartState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show empty cart state (check this before loading products)
    if (cartState.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Your cart is empty',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Add products from companies to get started',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Watch products provider with cart items as parameter
    // Only fetch if cart has items and is not loading
    final productsAsync = ref.watch(
      cartProductsProvider(cartState.items),
    );

    // Show loading state while products are loading
    if (productsAsync.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error state
    if (productsAsync.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Failed to load products',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                productsAsync.error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(cartProductsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final productMap = productsAsync.value ?? {};

    // Match cart items with products and group by company
    final companyGroups = _buildCompanyGroups(
      cartState.items,
      productMap,
    );

    // Show grouped cart items
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: companyGroups.length,
      itemBuilder: (context, index) {
        return _CompanyCartGroupWidget(
          group: companyGroups[index],
          onQuantityChanged: (productId, newQuantity, product) async {
            try {
              await ref.read(cartProvider.notifier).updateQuantity(
                    productId,
                    newQuantity,
                    product,
                  );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            }
          },
          onRemove: (productId) async {
            await ref.read(cartProvider.notifier).removeItem(productId);
          },
          onCheckout: (companyId, companyName, items, totalPrice) async {
            await _handleCheckout(
              context,
              ref,
              companyId,
              companyName,
              items,
              totalPrice,
            );
          },
        );
      },
    );
  }

  // Build company groups from cart items and products
  List<CompanyCartGroup> _buildCompanyGroups(
    List<CartItem> cartItems,
    Map<int, Product> productMap,
  ) {

    // Match cart items with products and fetch company info
    final itemsWithProducts = <CartItemWithProduct>[];
    for (final cartItem in cartItems) {
      final product = productMap[cartItem.productId];
      // Skip items with invalid products (missing product, company, or ID)
      if (product == null || product.companyId == null || product.id == null) {
        continue;
      }

      // Fetch company info (we'll need to handle this differently)
      // For now, we'll group by companyId and fetch company info in the widget
      itemsWithProducts.add(
        CartItemWithProduct(
          cartItem: cartItem,
          product: product,
          company: Company(
            id: product.companyId,
            name: '', // Will be fetched in widget
            location: '',
            companyType: CompanyType.supplier,
          ),
        ),
      );
    }

    // Group by companyId
    final companyGroupsMap = <int, List<CartItemWithProduct>>{};
    for (final item in itemsWithProducts) {
      final companyId = item.product.companyId;
      if (companyId != null) {
        companyGroupsMap.putIfAbsent(companyId, () => []).add(item);
      }
    }

    // Convert to CompanyCartGroup list (we'll fetch company info in the widget)
    return companyGroupsMap.entries.map((entry) {
      return CompanyCartGroup(
        company: entry.value.first.company,
        items: entry.value,
      );
    }).toList();
  }

  // Handle checkout for a specific company
  static Future<void> _handleCheckout(
    BuildContext context,
    WidgetRef ref,
    int supplierCompanyId,
    String companyName,
    List<CartItemWithProduct> items,
    int totalPrice,
  ) async {
    print('[CHECKOUT] Starting checkout for company: $supplierCompanyId');
    print('[CHECKOUT] Company name: $companyName');
    print('[CHECKOUT] Items count: ${items.length}');
    print('[CHECKOUT] Total price: $totalPrice');
    
    // Log each item
    for (var item in items) {
      print('[CHECKOUT] Item - Product ID: ${item.product.id}, Name: ${item.product.name}, Quantity: ${item.cartItem.count}');
    }
    
    // Show confirmation dialog
    print('[CHECKOUT] Showing confirmation dialog');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Confirm Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Complete order with $companyName?',
              style: Theme.of(dialogContext).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Total: $totalPrice ₸',
              style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Items: ${items.length}',
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    print('[CHECKOUT] Dialog result: $confirmed');
    
    if (confirmed != true) {
      print('[CHECKOUT] User cancelled checkout');
      return; // User cancelled
    }

    print('[CHECKOUT] User confirmed, getting user profile');
    // Get user profile to verify company
    final userState = ref.read(userProfileProvider);
    final user = userState.value;
    print('[CHECKOUT] User: ${user?.email}, Company ID: ${user?.companyId}');
    
    if (user?.companyId == null) {
      print('[CHECKOUT] ERROR: User company ID is null');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User company not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    print('[CHECKOUT] Verifying linking status');
    // Verify linking is accepted
    final linkingRepo = ref.read(linkingRepositoryProvider);
    Linking? linking;
    
    try {
      linking = await linkingRepo.getLinkingStatus(otherCompanyId: supplierCompanyId);
      print('[CHECKOUT] Linking status: ${linking?.status}, Linking ID: ${linking?.linkingId}');
    } catch (e) {
      print('[CHECKOUT] ERROR: Failed to get linking status: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify linking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (linking == null || linking.status != LinkingStatus.accepted) {
      print('[CHECKOUT] ERROR: Linking is null or not accepted. Status: ${linking?.status}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Linking with this supplier is not accepted'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    print('[CHECKOUT] Creating order request');
    // Create order request with products from this company
    // Filter out items with null product IDs
    final validItems = items.where((item) => item.product.id != null).toList();
    print('[CHECKOUT] Valid items count: ${validItems.length} (original: ${items.length})');
    
    if (validItems.isEmpty) {
      print('[CHECKOUT] ERROR: No valid items after filtering');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid products to order'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    print('[CHECKOUT] Mapping items to OrderProductCreate');
    final orderProducts = <OrderProductCreate>[];
    for (var itemWithProduct in validItems) {
      print('[CHECKOUT] Creating order product - ID: ${itemWithProduct.product.id}, Quantity: ${itemWithProduct.cartItem.count}');
      if (itemWithProduct.product.id == null) {
        print('[CHECKOUT] WARNING: Product ID is null for product: ${itemWithProduct.product.name}');
        continue;
      }
      orderProducts.add(OrderProductCreate(
        productId: itemWithProduct.product.id!,
        quantity: itemWithProduct.cartItem.count,
      ));
    }
    print('[CHECKOUT] Created ${orderProducts.length} order products');

    final orderRequest = OrderCreateRequest(products: orderProducts);
    print('[CHECKOUT] Order request created with ${orderRequest.products.length} products');

    // Create the order
    print('[CHECKOUT] Calling orderRepo.createOrder');
    print('[CHECKOUT] Supplier Company ID: $supplierCompanyId');
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      print('[CHECKOUT] Order repository obtained, creating order...');
      await orderRepo.createOrder(
        supplierCompanyId: supplierCompanyId,
        request: orderRequest,
      );
      print('[CHECKOUT] Order created successfully!');

      // Remove items for this company from cart
      print('[CHECKOUT] Removing items from cart');
      final cartNotifier = ref.read(cartProvider.notifier);
      for (var i = 0; i < validItems.length; i++) {
        final itemWithProduct = validItems[i];
        print('[CHECKOUT] Removing item ${i + 1}/${validItems.length} - Product ID: ${itemWithProduct.product.id}');
        if (itemWithProduct.product.id != null) {
          await cartNotifier.removeItem(itemWithProduct.product.id!);
          print('[CHECKOUT] Item removed successfully');
        } else {
          print('[CHECKOUT] WARNING: Skipping removal - product ID is null');
        }
      }
      print('[CHECKOUT] All items removed from cart');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      print('[CHECKOUT] Checkout completed successfully');
    } catch (e, stackTrace) {
      print('[CHECKOUT] ERROR: Exception during order creation: $e');
      print('[CHECKOUT] Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Widget to display a company's cart group
class _CompanyCartGroupWidget extends ConsumerWidget {
  const _CompanyCartGroupWidget({
    required this.group,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onCheckout,
  });

  final CompanyCartGroup group;
  final Future<void> Function(int productId, int newQuantity, Product product) onQuantityChanged;
  final Future<void> Function(int productId) onRemove;
  final Future<void> Function(
    int companyId,
    String companyName,
    List<CartItemWithProduct> items,
    int totalPrice,
  ) onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch company info
    final companyAsync = ref.watch(
      companyByIdProvider(group.company.id!),
    );

    return companyAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading company: $error'),
        ),
      ),
      data: (company) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Company header with logo and name
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: <Widget>[
                    // Company logo
                    if (company.logoUrl != null && company.logoUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          company.logoUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholderLogo(48),
                        ),
                      )
                    else
                      _buildPlaceholderLogo(48),
                    const SizedBox(width: 12),
                    // Company name
                    Expanded(
                      child: Text(
                        company.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Cart items for this company
              ...group.items.map((itemWithProduct) => _CartItemWidget(
                    itemWithProduct: itemWithProduct,
                    onQuantityChanged: onQuantityChanged,
                    onRemove: onRemove,
                  )),
              const Divider(height: 1),
              // Total and checkout button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      'Total: ${group.totalPrice} ₸',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          print('[CHECKOUT-BTN] Pressed. Company ID from Group: ${group.company.id}');
                          print('[CHECKOUT-BTN] Company ID from API: ${company.id}');
                          
                          final idToUse = company.id ?? group.company.id!;
                          
                          onCheckout(
                            idToUse,
                            company.name,
                            group.items,
                            group.totalPrice,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: ButtonSizes.mdFill,
                        ),
                        child: const Text('Checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build placeholder logo
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
}

// Widget to display a single cart item
class _CartItemWidget extends StatefulWidget {
  const _CartItemWidget({
    required this.itemWithProduct,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartItemWithProduct itemWithProduct;
  final Future<void> Function(int productId, int newQuantity, Product product) onQuantityChanged;
  final Future<void> Function(int productId) onRemove;

  @override
  State<_CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<_CartItemWidget> {
  late int _currentQuantity;
  final TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentQuantity = widget.itemWithProduct.cartItem.count;
    _quantityController.text = _currentQuantity.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateQuantity(int newQuantity) {
    if (newQuantity == _currentQuantity) {
      return;
    }

    setState(() {
      _currentQuantity = newQuantity;
      _quantityController.text = newQuantity.toString();
    });

    widget.onQuantityChanged(
      widget.itemWithProduct.product.id!,
      newQuantity,
      widget.itemWithProduct.product,
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.itemWithProduct.product;
    final cartItem = widget.itemWithProduct.cartItem;
    final itemTotal = product.retailPrice * cartItem.count;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Tappable product info area
          Expanded(
            child: InkWell(
              onTap: () {
                // Navigate to product detail view when tapped
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProductDetailView(
                      product: product,
                      showAddToCart: true,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Product image
                  if (product.pictureUrls.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.pictureUrls.first,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image_not_supported),
                    ),
                  const SizedBox(width: 12),
                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.description,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${product.retailPrice} ₸ / ${product.unit}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total: $itemTotal ₸',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Quantity and remove controls
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              // Quantity input/dropdown
              SizedBox(
                width: 80,
                child: DropdownButtonFormField<int>(
                  value: _currentQuantity,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    isDense: true,
                  ),

                  items: List.generate(
                    (product.stockQuantity - product.minimumOrder + 1).clamp(0, 100),
                    (index) => product.minimumOrder + index,
                  ).map((value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updateQuantity(value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Remove button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => widget.onRemove(product.id!),
                color: Theme.of(context).colorScheme.error,
                tooltip: 'Remove',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
