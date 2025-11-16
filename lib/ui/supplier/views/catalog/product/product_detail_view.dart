import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/user_profile_provider.dart';
import '../../../../../data/models/app_user.dart';
import '../../../../../data/models/product.dart';
import '../../../../../data/repositories/product_repository.dart';
import '../../../../../l10n/app_localizations.dart';
import 'edit_product_view.dart';
import 'product_image_gallery_view.dart';

// Product details page showing full information and action buttons by role.
class ProductDetailView extends ConsumerStatefulWidget {
  const ProductDetailView({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<ProductDetailView> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;

    // Determine user role to control visibility of actions.
    final AsyncValue<AppUser?> userState = ref.watch(userProfileProvider);
    final AppUser? user = userState.value;

    // Only owners and managers can see edit/delete actions.
    final bool canManage = user != null &&
        (user.role == UserRole.owner || user.role == UserRole.manager);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: <Widget>[
          // Edit button - opens edit view.
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditProductView(product: widget.product),
                  ),
                );
              },
            ),

          // Delete button - shows confirmation dialog.
          if (canManage)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              onPressed: _isDeleting ? null : () => _handleDelete(context, localization),
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
            if (widget.product.pictureUrls.isNotEmpty) ...<Widget>[
              // Horizontal scrollable list of product images.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.product.pictureUrls
                      .map(
                        (url) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              // Open full-screen gallery starting from the tapped image.
                              final int initialIndex = widget.product.pictureUrls.indexOf(url);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ProductImageGalleryView(
                                    imageUrls: widget.product.pictureUrls,
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
              ),
              const SizedBox(height: 16),
            ],

            // Product name - bold/semibold
            Text(
              widget.product.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),

            // Product description - larger size
            Text(
              widget.product.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 16),

            // Quantities and pricing
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _kv('Unit', widget.product.unit),
            _kv('Stock quantity', widget.product.stockQuantity.toString()),
            _kv('Retail price', widget.product.retailPrice.toString()),
            _kv('Bulk price', widget.product.bulkPrice.toString()),
            _kv('Minimum order', widget.product.minimumOrder.toString()),
            _kv('Threshold', widget.product.threshold.toString()),
          ],
        ),
      ),
    );
  }

  // Handle product deletion with confirmation dialog.
  Future<void> _handleDelete(BuildContext context, AppLocalizations localization) async {
    // Show confirmation dialog.
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(localization.catalogDeleteProductTitle),
        content: Text(localization.catalogDeleteProductMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(localization.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(localization.commonConfirm),
          ),
        ],
      ),
    );

    // If user cancelled, do nothing.
    if (confirmed != true) {
      return;
    }

    // Ensure product has an ID for deletion.
    if (widget.product.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.catalogDeleteProductErrorGeneric('Product ID is missing')),
          ),
        );
      }
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final ProductRepository repository = ref.read(productRepositoryProvider);

      await repository.deleteProduct(productId: widget.product.id!);

      if (mounted) {
        // Show success message.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.catalogDeleteProductSuccess),
          ),
        );

        // Navigate back to previous screen.
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localization.catalogDeleteProductErrorGeneric(error.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
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


