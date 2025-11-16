import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/user_profile_provider.dart';
import '../../../../../data/models/app_user.dart';
import '../../../../../data/models/product.dart';
import 'product_image_gallery_view.dart';

// Product details page showing full information and action buttons by role.
class ProductDetailView extends ConsumerWidget {
  const ProductDetailView({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine user role to control visibility of actions.
    final AsyncValue<AppUser?> userState = ref.watch(userProfileProvider);
    final AppUser? user = userState.value;

    // Only owners and managers can see edit/delete actions.
    final bool canManage = user != null &&
        (user.role == 'owner' || user.role == 'manager');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: <Widget>[
          // Edit button is a visible placeholder (logic not implemented).
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Edit not implemented as requested.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit: not implemented yet')),
                );
              },
            ),

          // Delete button is a visible placeholder (logic not implemented).
          if (canManage)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                // Delete not implemented as requested.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete: not implemented yet')),
                );
              },
            ),
        ],
      ),

      // Full product data listing.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Images section - placed first, before header and description
            if (product.pictureUrls.isNotEmpty) ...<Widget>[
              // Only enable horizontal scrolling when there are more than 5 images
              product.pictureUrls.length > 5
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: product.pictureUrls
                            .map(
                              (url) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    // Open full-screen gallery starting from the tapped image.
                                    final int initialIndex = product.pictureUrls.indexOf(url);
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ProductImageGalleryView(
                                          imageUrls: product.pictureUrls,
                                          initialIndex: initialIndex < 0 ? 0 : initialIndex,
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 144,
                                      height: 144,
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : Row(
                      children: product.pictureUrls
                          .map(
                            (url) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  // Open full-screen gallery starting from the tapped image.
                                  final int initialIndex = product.pictureUrls.indexOf(url);
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ProductImageGalleryView(
                                        imageUrls: product.pictureUrls,
                                        initialIndex: initialIndex < 0 ? 0 : initialIndex,
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 144,
                                    height: 144,
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
              const SizedBox(height: 16),
            ],

            // Product name - bold/semibold
            Text(
              product.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),

            // Product description - larger size
            Text(
              product.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 16),

            // Quantities and pricing
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _kv('Unit', product.unit),
            _kv('Stock quantity', product.stockQuantity.toString()),
            _kv('Retail price', product.retailPrice.toString()),
            _kv('Bulk price', product.bulkPrice.toString()),
            _kv('Minimum order', product.minimumOrder.toString()),
            _kv('Threshold', product.threshold.toString()),
          ],
        ),
      ),
    );
  }

  // Simple key-value row.
  Widget _kv(String keyLabel, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 140,
            child: Text(
              keyLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}


