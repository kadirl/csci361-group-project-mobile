import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/button_sizes.dart';
import '../../../data/models/company.dart';
import '../../../data/models/linking.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/company_repository.dart';
import '../../../data/repositories/linking_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../supplier/views/catalog/product/product_detail_view.dart';

// Provider to load a single company by ID.
final companyByIdProvider = FutureProvider.autoDispose.family<Company, int>((
  ref,
  companyId,
) async {
  final repo = ref.read(companyRepositoryProvider);
  try {
    final company = await repo.getCompany(
      companyId: companyId,
      forceRefresh: true,
    );
    return company;
  } catch (e) {
    rethrow;
  }
});

// Provider to load linking status between current user's company and target company.
final linkingStatusProvider = FutureProvider.autoDispose.family<Linking?, int>((
  ref,
  otherCompanyId,
) async {
  final repo = ref.read(linkingRepositoryProvider);
  try {
    final linking = await repo.getLinkingStatus(otherCompanyId: otherCompanyId);
    return linking;
  } catch (e) {
    rethrow;
  }
});

// Provider to load products for a company.
final companyProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, int>((ref, companyId) async {
      final repo = ref.read(productRepositoryProvider);
      try {
        final products = await repo.listProducts(companyId: companyId);
        return products;
      } catch (e) {
        rethrow;
      }
    });

// Company detail page showing full company information.
class CompanyDetailView extends ConsumerStatefulWidget {
  const CompanyDetailView({super.key, required this.companyId});

  final int companyId;

  @override
  ConsumerState<CompanyDetailView> createState() => _CompanyDetailViewState();
}

class _CompanyDetailViewState extends ConsumerState<CompanyDetailView> {
  @override
  void initState() {
    super.initState();
    // Refresh linking status when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(linkingStatusProvider(widget.companyId));
    });
  }

  // Show dialog to send linking request.
  Future<void> _showSendLinkingDialog() async {
    final TextEditingController messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Send Linking Request'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: messageController,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Enter your message...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Message cannot be empty';
              }
              return null;
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (result == true && messageController.text.trim().isNotEmpty) {
      await _sendLinkingRequest(messageController.text.trim());
    }
  }

  // Send linking request.
  Future<void> _sendLinkingRequest(String message) async {
    try {
      final linkingRepo = ref.read(linkingRepositoryProvider);
      await linkingRepo.createLinking(
        companyId: widget.companyId,
        request: LinkingRequest(message: message),
      );

      // Refresh linking status
      ref.invalidate(linkingStatusProvider(widget.companyId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Linking request sent successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending linking request: $error')),
        );
      }
    }
  }

  // Build products section based on linking status.
  Widget _buildProductsSection(
    Company company,
    AsyncValue<Linking?> linkingStatusAsync,
  ) {
    if (company.companyType != CompanyType.supplier) {
      return const SizedBox.shrink();
    }

    return linkingStatusAsync.when(
      loading: () {
        return const SizedBox.shrink();
      },
      error: (e, s) {
        return const SizedBox.shrink();
      },
      data: (linking) {
        if (linking?.status != LinkingStatus.accepted) {
          return const SizedBox.shrink();
        }

        // Show products when linking is accepted
        final productsAsync = ref.watch(
          companyProductsProvider(widget.companyId),
        );

        return productsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
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
                    ref.invalidate(companyProductsProvider(widget.companyId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (products) {
            if (products.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No products available',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Products',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...products.map((product) => _ProductCard(product: product)),
              ],
            );
          },
        );
      },
    );
  }

  // Build bottom navigation bar with appropriate button based on linking status.
  Widget? _buildBottomNavigationBar(Linking? linking) {
    if (linking == null) {
      // No linking exists - show "Send Linking" button
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: ButtonSizes.mdFill),
            onPressed: _showSendLinkingDialog,
            child: const Text('Send Linking'),
          ),
        ),
      );
    }

    switch (linking.status) {
      case LinkingStatus.pending:
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: ButtonSizes.mdFill),
              onPressed: null,
              child: const Text('Linking Pending'),
            ),
          ),
        );
      case LinkingStatus.rejected:
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: ButtonSizes.mdFill),
              onPressed: null,
              child: const Text('Linking Rejected'),
            ),
          ),
        );
      case LinkingStatus.unlinked:
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: ButtonSizes.mdFill),
              onPressed: null,
              child: const Text('Unlinked'),
            ),
          ),
        );
      case LinkingStatus.accepted:
        // No button shown when accepted
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyByIdProvider(widget.companyId));
    final linkingStatusAsync = ref.watch(
      linkingStatusProvider(widget.companyId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Company Details')),
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
                    ref.invalidate(companyByIdProvider(widget.companyId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (company) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Company logo (with placeholder if not available).
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      children: [
                        company.logoUrl != null && company.logoUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 128,
                                  height: 128,
                                  child: Image.network(
                                    company.logoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildPlaceholderLogo(128),
                                  ),
                                ),
                              )
                            : _buildPlaceholderLogo(128),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            company.companyType == CompanyType.supplier
                                ? AppLocalizations.of(
                                    context,
                                  )!.companyTypeSupplier
                                : AppLocalizations.of(
                                    context,
                                  )!.companyTypeConsumer,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
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
                if (company.description != null &&
                    company.description!.isNotEmpty) ...[
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
                  const SizedBox(height: 24),
                ],

                // Products section (only shown when linking is accepted AND company is a supplier).
                // Products section (only shown when linking is accepted AND company is a supplier).
                _buildProductsSection(company, linkingStatusAsync),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: linkingStatusAsync.when(
        loading: () => null,
        error: (_, __) => null,
        data: (linking) => _buildBottomNavigationBar(linking),
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
    child: Icon(Icons.business, size: size / 2, color: Colors.grey),
  );
}

// Visual card that renders all product data fields at a glance.
// Copied from catalog_view.dart
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    // Build a clean, readable tile with key product attributes.
    return SizedBox(
      width: double.infinity,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
          borderRadius: BorderRadius.circular(12),
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
                    physics: const ClampingScrollPhysics(),
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
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image_not_supported),
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
      ),
    );
  }
}
