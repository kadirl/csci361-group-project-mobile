import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/user_profile_provider.dart';
import '../../../core/providers/company_profile_provider.dart';
import '../../../core/providers/complaint_provider.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/company.dart';
import '../../../data/models/complaint.dart';
import '../../../data/models/linking.dart';
import '../../../data/models/order.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/company_repository.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../data/repositories/linking_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../supplier/views/catalog/product/product_detail_view.dart';
import '../../shared/linkings/linking_detail_view.dart';
import '../../shared/chat/chat_view.dart';
import '../../shared/complaints/complaint_detail_view.dart';
import '../../consumer/views/company_detail_view.dart';

/// Order detail view showing full information about an order.
class OrderDetailView extends ConsumerStatefulWidget {
  const OrderDetailView({
    super.key,
    required this.order,
    required this.companyIdToLoad,
  });

  final Order order;
  final int Function(Linking linking) companyIdToLoad;

  @override
  ConsumerState<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends ConsumerState<OrderDetailView> {
  // Loaded data
  Linking? _linking;
  Company? _consumerCompany;
  Company? _supplierCompany;
  AppUser? _consumerUser;
  AppUser? _salesperson;
  List<OrderProduct> _orderProducts = [];
  Order? _currentOrder; // Track current order for status updates
  bool _isLoading = false;
  String? _error;
  Complaint? _complaint; // Track complaint for this order
  bool _isLoadingComplaint = false;

  @override
  void initState() {
    super.initState();
    // Initialize current order with the passed order
    _currentOrder = widget.order;
    _loadData();
    _loadComplaint();
  }

  // Load all necessary data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load linking by getting all linkings and finding the matching one
      final userState = ref.read(userProfileProvider);
      final appUser = userState.value;
      
      if (appUser?.companyId == null) {
        throw Exception('User company ID not found');
      }

      final linkingRepo = ref.read(linkingRepositoryProvider);
      final linkings = await linkingRepo.getLinkingsByCompany(
        companyId: appUser!.companyId!,
      );
      
      _linking = linkings.firstWhere(
        (l) => l.linkingId == widget.order.linkingId,
        orElse: () => throw Exception('Linking not found'),
      );
      
      debugPrint('OrderDetailView -> Linking loaded: ${_linking?.linkingId}');

      // Load full order details (may include products)
      // Wrap in try-catch to handle cases where the order endpoint returns 404
      try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final fullOrder = await orderRepo.getOrder(orderId: widget.order.orderId);

      // Update current order state
      if (mounted) {
        setState(() {
          _currentOrder = fullOrder;
        });
        }
      } catch (e) {
        debugPrint('OrderDetailView -> Failed to fetch full order details: $e');
        debugPrint('OrderDetailView -> Using order data from widget instead');
        // If fetching fails (e.g., 404), just use the order passed in
        if (mounted) {
          setState(() {
            _currentOrder = widget.order;
          });
        }
      }

      // Load companies
      final companyRepo = ref.read(companyRepositoryProvider);
      _consumerCompany = await companyRepo.getCompany(
        companyId: _linking!.consumerCompanyId,
      );
      _supplierCompany = await companyRepo.getCompany(
        companyId: _linking!.supplierCompanyId,
      );

      // Load users
      final userRepo = ref.read(userRepositoryProvider);
      
      // Only load consumer user if we have a valid ID
      if (widget.order.consumerStaffId > 0) {
        try {
      _consumerUser = await userRepo.getUserById(userId: widget.order.consumerStaffId);
        } catch (e) {
          debugPrint('OrderDetailView -> Failed to load consumer user: $e');
          // Continue without consumer user data
        }
      } else {
        debugPrint('OrderDetailView -> Invalid consumer staff ID (${widget.order.consumerStaffId}), skipping user load');
      }
      
      // Only load salesperson if we have a valid ID
      if (_linking!.assignedSalesmanUserId != null && _linking!.assignedSalesmanUserId! > 0) {
        try {
        _salesperson = await userRepo.getUserById(
          userId: _linking!.assignedSalesmanUserId!,
        );
        } catch (e) {
          debugPrint('OrderDetailView -> Failed to load salesperson: $e');
          // Continue without salesperson data
        }
      }

      // Load products if not included in order
      final productRepo = ref.read(productRepositoryProvider);
      final List<OrderProduct> productsWithDetails = [];

      // Get all supplier products to find the ones in the order
      List<Product> supplierProducts = [];
      if (_linking?.supplierCompanyId != null) {
        try {
          supplierProducts = await productRepo.listProducts(
            companyId: _linking!.supplierCompanyId,
          );
        } catch (e) {
          debugPrint('Failed to load supplier products: $e');
        }
      }

      for (final orderProduct in (_currentOrder ?? widget.order).products ?? []) {
        Product? product = orderProduct.product;

        // If product not loaded, find it from supplier products
        if (product == null) {
          try {
            product = supplierProducts.firstWhere(
              (p) => p.id == orderProduct.productId,
              orElse: () => throw Exception('Product not found'),
            );
          } catch (e) {
            debugPrint('Failed to find product ${orderProduct.productId}: $e');
          }
        }

        // Calculate price per unit based on threshold
        int pricePerUnit = product?.retailPrice ?? 0;
        if (product != null && orderProduct.quantity >= product.threshold) {
          pricePerUnit = product.bulkPrice;
        }

        // Calculate subtotal
        final int subtotal = (pricePerUnit * orderProduct.quantity).toInt();

        productsWithDetails.add(
          OrderProduct(
            productId: orderProduct.productId,
            quantity: orderProduct.quantity,
            product: product,
            pricePerUnit: pricePerUnit,
            subtotal: subtotal,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _orderProducts = productsWithDetails;
          _isLoading = false;
          // Include all loaded data in setState to trigger rebuild
          // (companies, linking, users are already set, but explicitly including
          // them makes the state update explicit)
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Load complaint for this order
  Future<void> _loadComplaint() async {
    debugPrint('OrderDetailView -> Loading complaint for order ${widget.order.orderId}');
    setState(() {
      _isLoadingComplaint = true;
    });

    try {
      // Call repository directly instead of using provider
      final repository = ref.read(complaintRepositoryProvider);
      final complaintAsync = await repository.getComplaintByOrderId(
        orderId: widget.order.orderId,
      );

      debugPrint('OrderDetailView -> Complaint loaded: ${complaintAsync?.complaintId ?? 'null'}');

      if (mounted) {
        setState(() {
          _complaint = complaintAsync;
          _isLoadingComplaint = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('OrderDetailView -> Error loading complaint: $e');
      debugPrint('OrderDetailView -> Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _complaint = null;
          _isLoadingComplaint = false;
        });
      }
    }
  }

  // Format date string
  String _formatDate(String? dateString, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (dateString == null || dateString.isEmpty) {
      return l10n.commonNA;
    }

    try {
      final DateTime dateTime = DateTime.parse(dateString);
      final DateFormat formatter = DateFormat('MMM dd, yyyy • HH:mm');
      return formatter.format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  // Get complaint status color
  Color _getComplaintStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.open:
        return Colors.orange;
      case ComplaintStatus.escalated:
        return Colors.red;
      case ComplaintStatus.inProgress:
        return Colors.blue;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.closed:
        return Colors.grey;
    }
  }

  // Get complaint status display name
  String _getComplaintStatusDisplayName(ComplaintStatus status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case ComplaintStatus.open:
        return l10n.complaintStatusOpen;
      case ComplaintStatus.escalated:
        return l10n.complaintStatusEscalated;
      case ComplaintStatus.inProgress:
        return l10n.complaintStatusInProgress;
      case ComplaintStatus.resolved:
        return l10n.complaintStatusResolved;
      case ComplaintStatus.closed:
        return l10n.complaintStatusClosed;
    }
  }

  // Check if current user is a consumer
  bool _isConsumer() {
    final companyState = ref.read(companyProfileProvider);
    final currentCompany = companyState.value;
    return currentCompany?.companyType == CompanyType.consumer;
  }

  // Show create complaint dialog
  Future<void> _showCreateComplaintDialog() async {
    final TextEditingController descriptionController = TextEditingController();

    final l10n = AppLocalizations.of(context)!;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.orderCreateComplaint),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.orderCreateComplaintReason),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: l10n.orderComplaintReasonLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 5,
              minLines: 3,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              if (descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(l10n.orderComplaintReasonRequired),
                  ),
                );
                return;
              }
              Navigator.of(dialogContext).pop(true);
            },
            child: Text(l10n.commonCreate),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final String description = descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.orderComplaintReasonRequired),
        ),
      );
      return;
    }

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      final complaintNotifier = ref.read(orderComplaintProvider.notifier);
      await complaintNotifier.createComplaint(
        orderId: widget.order.orderId,
        description: description,
      );

      // Invalidate and reload complaint
      ref.invalidate(complaintByOrderIdProvider(widget.order.orderId));
      await _loadComplaint();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.orderComplaintCreatedSuccess),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.orderComplaintCreateError(error.toString())),
          ),
        );
      }
    }
  }

  // Check if current user can change order status
  bool _canChangeOrderStatus() {
    // Wait for user profile to load
    final userState = ref.read(userProfileProvider);
    final appUser = userState.value;

    // User must be authenticated and have a company
    if (appUser == null || appUser.companyId == null) {
      return false;
    }

    // Must have linking loaded
    if (_linking == null) {
      return false;
    }

    // Linking must be accepted (required for orders to exist)
    if (_linking!.status != LinkingStatus.accepted) {
      return false;
    }

    // Must be supplier company (consumers cannot change order status)
    // Check if user's company ID matches the supplier company ID from the linking
    if (appUser.companyId != _linking!.supplierCompanyId) {
      return false;
    }

    // Staff can only change status if they are the assigned salesperson
    if (appUser.role == UserRole.staff) {
      if (_linking!.assignedSalesmanUserId == null ||
          _linking!.assignedSalesmanUserId != appUser.id) {
        return false;
      }
    }

    // Manager and Owner can always change status for their company
    if (appUser.role == UserRole.manager || appUser.role == UserRole.owner) {
      return true;
    }

    return false;
  }

  // Handle order status change
  Future<void> _handleStatusChange(OrderStatus newStatus) async {
    final currentOrder = _currentOrder ?? widget.order;

    final l10n = AppLocalizations.of(context)!;
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.orderChangeStatusTitle),
        content: Text(
          l10n.orderChangeStatusMessage(currentOrder.status.name.toUpperCase(), newStatus.name.toUpperCase()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.orderChange),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      await orderRepo.updateOrderStatus(
        orderId: currentOrder.orderId,
        status: newStatus,
      );

      // Reload order data to get updated status
      final updatedOrder = await orderRepo.getOrder(orderId: currentOrder.orderId);

      if (mounted) {
        setState(() {
          _currentOrder = updatedOrder;
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.orderStatusChanged(newStatus.name.toUpperCase())),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.orderStatusChangeError(error.toString())),
          ),
        );
      }
    }
  }

  // Build status change dropdown (only called if user has permission)
  Widget _buildStatusChangeDropdown() {
    final currentOrder = _currentOrder ?? widget.order;

    return PopupMenuButton<OrderStatus>(
      icon: const Icon(Icons.arrow_drop_down),
      tooltip: AppLocalizations.of(context)!.orderChangeStatusTitle,
      onSelected: _handleStatusChange,
      itemBuilder: (BuildContext context) {
        return OrderStatus.values.map((OrderStatus status) {
          return PopupMenuItem<OrderStatus>(
            value: status,
            enabled: status != currentOrder.status,
            child: Row(
              children: [
                if (status == currentOrder.status)
                  Icon(
                    Icons.check,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  )
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 8),
                Text(status.name.toUpperCase()),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.orderDetailsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.orderDetailsTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${l10n.commonError}: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.order.orderId}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order status and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${widget.order.orderId}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        (_currentOrder ?? widget.order).status.name.toUpperCase(),
                      ),
                    ),
                    if (_canChangeOrderStatus()) ...[
                      const SizedBox(width: 4),
                      _buildStatusChangeDropdown(),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  l10n.orderCreated(_formatDate((_currentOrder ?? widget.order).createdAt, context)),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if ((_currentOrder ?? widget.order).updatedAt !=
                    (_currentOrder ?? widget.order).createdAt) ...[
                  const SizedBox(width: 16),
                  Text(
                    l10n.orderUpdated(_formatDate((_currentOrder ?? widget.order).updatedAt, context)),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Linking information
            Text(
              l10n.orderLinking,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (_linking != null)
              Card(
                child: InkWell(
                  onTap: () {
                    final userState = ref.read(userProfileProvider);
                    final appUser = userState.value;
                    final isSupplier = appUser?.companyId == _linking!.supplierCompanyId;

                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LinkingDetailView(
                          linking: _linking!,
                          showAcceptRejectButtons: isSupplier,
                          companyIdToLoad: isSupplier
                              ? _linking!.consumerCompanyId
                              : _linking!.supplierCompanyId,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${l10n.orderLinking} #${_linking!.linkingId ?? l10n.commonNA}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    '${l10n.orderLinking} #${widget.order.linkingId}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Chat button (available for all orders)
            FilledButton.icon(
              onPressed: _linking != null
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatView(
                            orderId: widget.order.orderId,
                            order: _currentOrder ?? widget.order,
                            linking: _linking!,
                          ),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.chat),
              label: Text(l10n.complaintOpenChat),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),

            // Create Complaint button (consumer only, hidden if complaint exists)
            if (_isConsumer() && _complaint == null && !_isLoadingComplaint)
              FilledButton.icon(
                onPressed: _showCreateComplaintDialog,
                icon: const Icon(Icons.report_problem),
                label: Text(l10n.orderCreateComplaint),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.orange,
                ),
              ),
            if (_isConsumer() && _complaint == null && !_isLoadingComplaint)
            const SizedBox(height: 24),

            // Complaint status section (visible to both sides if complaint exists)
            if (_complaint != null) ...[
              Text(
                l10n.orderComplaint,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ComplaintDetailView(
                          complaintId: _complaint!.complaintId,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                _getComplaintStatusDisplayName(_complaint!.status, context),
                              ),
                              backgroundColor: _getComplaintStatusColor(
                                _complaint!.status,
                              ).withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: _getComplaintStatusColor(_complaint!.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _complaint!.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.complaintCreated.replaceAll('{date}', _formatDate(_complaint!.createdAt, context)),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Company information (consumer sees supplier, supplier sees consumer)
            // Assigned personnel (below company card)
            _buildCompanyAndPersonnelSection(ref),
            
            const SizedBox(height: 24),

            // Order products
            Text(
              l10n.orderProducts,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (_orderProducts.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(l10n.orderNoProducts),
                ),
              )
            else
              ..._orderProducts.map((orderProduct) => _buildProductCard(orderProduct)),

            const SizedBox(height: 24),

            // Total price
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.orderTotal,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${(_currentOrder ?? widget.order).totalPrice} ₸',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build company and assigned personnel section
  Widget _buildCompanyAndPersonnelSection(WidgetRef ref) {
    // Determine if current user is consumer or supplier
    final companyState = ref.watch(companyProfileProvider);
    final currentCompany = companyState.value;

    // Determine which company and personnel to show
    Company? companyToShow;
    int? companyIdToShow;
    AppUser? personnelToShow;
    String companyLabel;
    String personnelLabel;

    final l10n = AppLocalizations.of(context)!;
    if (currentCompany?.companyType == CompanyType.consumer) {
      // Consumer sees supplier company
      companyToShow = _supplierCompany;
      companyIdToShow = _linking?.supplierCompanyId;
      companyLabel = l10n.orderSupplier;
      // Consumer sees assigned salesperson
      personnelToShow = _salesperson;
      personnelLabel = l10n.orderAssignedSalesperson;
    } else {
      // Supplier sees consumer company
      companyToShow = _consumerCompany;
      companyIdToShow = _linking?.consumerCompanyId;
      companyLabel = l10n.orderConsumer;
      // Supplier sees consumer staff who created the order
      personnelToShow = _consumerUser;
      personnelLabel = l10n.orderConsumerStaff;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company card
        Text(
          companyLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: companyIdToShow != null
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CompanyDetailView(
                          companyId: companyIdToShow!,
                        ),
                      ),
                    );
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      companyToShow?.name ?? '${l10n.companiesCompany} #${companyIdToShow ?? l10n.commonNA}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (companyIdToShow != null)
                    const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Assigned personnel card
        Text(
          personnelLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: InkWell(
            onTap: personnelToShow != null
                ? () {
                    final personnel = personnelToShow!;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => UserProfileDetailView(user: personnel),
                      ),
                    );
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (personnelToShow != null) ...[
                          Text(
                            '${personnelToShow.firstName} ${personnelToShow.lastName}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            personnelToShow.email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            personnelToShow.role.name.toUpperCase(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ] else
                          Text(
                            l10n.commonNotAssigned,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                      ],
                    ),
                  ),
                  if (personnelToShow != null)
                    const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build product card (reusing style from catalog)
  Widget _buildProductCard(OrderProduct orderProduct) {
    final product = orderProduct.product;

    // Only make clickable if product details are loaded
    if (product == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.orderProductId(orderProduct.productId),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.orderQuantity(orderProduct.quantity),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.orderPricePerUnit(orderProduct.pricePerUnit ?? 0),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Text(
                    AppLocalizations.of(context)!.orderSubtotal(orderProduct.subtotal ?? 0),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailView(
                product: product,
                showAddToCart: true,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Product images
            if (product.pictureUrls.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 8),
                ],
              ),

            // Product name
            Text(
              product.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),

            const SizedBox(height: 4),

            // Product description
            if (product.description.isNotEmpty)
              Text(
                product.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 8),

            // Quantity and price information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.orderQuantity(orderProduct.quantity)} ${product.unit}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.orderPricePerUnit(orderProduct.pricePerUnit ?? 0),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Text(
                  '${orderProduct.subtotal ?? 0} ₸',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

