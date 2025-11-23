import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/user_profile_provider.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/company.dart';
import '../../../data/models/linking.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/company_repository.dart';
import '../../../data/repositories/linking_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../linkings/linking_detail_view.dart';
import 'order_detail_view.dart';

/// Shared orders view with grouping by linking and status filtering.
///
/// [companyIdToLoad] - Function that returns the company ID to load for each linking
///   (supplierCompanyId for consumer, consumerCompanyId for supplier).
class OrdersView extends ConsumerStatefulWidget {
  const OrdersView({
    super.key,
    required this.companyIdToLoad,
  });

  final int Function(Linking linking) companyIdToLoad;

  @override
  ConsumerState<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends ConsumerState<OrdersView> {
  // Cache the loaded linkings and orders
  List<Linking>? _cachedLinkings;
  Map<int, List<Order>> _ordersByLinking = {};
  final Map<int, Company> _companiesCache = {};
  bool _isLoading = false;
  String? _error;

  // Selected status filter (null means "all")
  OrderStatus? _selectedStatus;

  // Search controller and query for filtering by company name
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Listen to search field changes to update filter
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    // Dispose the controller to avoid memory leaks
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Handle search field changes without triggering full rebuild
  void _onSearchChanged() {
    final String newQuery = _searchController.text.toLowerCase().trim();
    if (newQuery != _searchQuery) {
      setState(() {
        _searchQuery = newQuery;
      });
    }
  }

  // Load linkings and orders
  Future<void> _loadData() async {
    final userState = ref.read(userProfileProvider);
    final appUser = userState.value;

    if (appUser?.companyId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load linkings
      final linkingRepo = ref.read(linkingRepositoryProvider);
      final linkings = await linkingRepo.getLinkingsByCompany(
        companyId: appUser!.companyId!,
      );

      // Filter linkings based on user role
      final filteredLinkings = _filterLinkingsByRole(linkings, appUser);

      // Load companies for filtered linkings
      await _loadCompanies(filteredLinkings);

      // Load orders for each linking
      final orderRepo = ref.read(orderRepositoryProvider);
      final Map<int, List<Order>> ordersMap = {};

      for (final linking in filteredLinkings) {
        if (linking.linkingId != null) {
          try {
            final orders = await orderRepo.getOrdersByLinking(
              linkingId: linking.linkingId!,
            );
            ordersMap[linking.linkingId!] = orders;
          } catch (e) {
            // If loading orders fails for a linking, continue with others
            debugPrint('Failed to load orders for linking ${linking.linkingId}: $e');
            ordersMap[linking.linkingId!] = [];
          }
        }
      }

      if (mounted) {
        setState(() {
          _cachedLinkings = filteredLinkings;
          _ordersByLinking = ordersMap;
          _isLoading = false;
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

  // Filter linkings based on user role
  List<Linking> _filterLinkingsByRole(List<Linking> linkings, AppUser user) {
    // Managers and owners see all linkings
    if (user.role == UserRole.manager || user.role == UserRole.owner) {
      return linkings;
    }

    // Staff can only see linkings where they are assigned as salesman
    if (user.role == UserRole.staff && user.id != null) {
      return linkings
          .where((linking) => linking.assignedSalesmanUserId == user.id)
          .toList();
    }

    return [];
  }

  // Load companies for linkings
  Future<void> _loadCompanies(List<Linking> linkings) async {
    final companyRepo = ref.read(companyRepositoryProvider);
    final Set<int> uniqueCompanyIds = linkings
        .map((linking) => widget.companyIdToLoad(linking))
        .where((id) => id > 0 && !_companiesCache.containsKey(id))
        .toSet();

    for (final companyId in uniqueCompanyIds) {
      try {
        final company = await companyRepo.getCompany(companyId: companyId);
        _companiesCache[companyId] = company;
      } catch (e) {
        debugPrint('Failed to load company $companyId: $e');
      }
    }
  }

  // Get company from cache
  Company? _getCompany(int companyId) {
    return _companiesCache[companyId];
  }

  // Filter orders by status
  List<Order> _filterOrdersByStatus(List<Order> orders) {
    if (_selectedStatus == null) {
      return orders;
    }
    return orders.where((order) => order.status == _selectedStatus).toList();
  }

  // Filter linking groups by company name based on search query
  List<_LinkingOrdersGroup> _filterLinkingGroupsByCompanyName(
    List<_LinkingOrdersGroup> groups,
  ) {
    if (_searchQuery.isEmpty) {
      return groups;
    }

    return groups
        .where((group) {
          final companyName = group.company?.name.toLowerCase() ?? '';
          return companyName.contains(_searchQuery);
        })
        .toList();
  }

  // Format date string to human-readable format
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }

    try {
      final DateTime dateTime = DateTime.parse(dateString);
      final DateFormat formatter = DateFormat('MMM dd, yyyy • HH:mm');
      return formatter.format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_cachedLinkings == null || _cachedLinkings!.isEmpty) {
      return const Center(child: Text('No linkings found'));
    }

    // Build list of linkings with their orders
    final List<_LinkingOrdersGroup> linkingGroups = [];

    for (final linking in _cachedLinkings!) {
      if (linking.linkingId != null) {
        final orders = _ordersByLinking[linking.linkingId!] ?? [];
        final filteredOrders = _filterOrdersByStatus(orders);

        // Only show linkings that have at least one order (after status filtering)
        if (filteredOrders.isNotEmpty) {
          linkingGroups.add(
            _LinkingOrdersGroup(
              linking: linking,
              orders: filteredOrders,
              company: _getCompany(widget.companyIdToLoad(linking)),
            ),
          );
        }
      }
    }

    // Filter by company name based on search query
    final filteredLinkingGroups =
        _filterLinkingGroupsByCompanyName(linkingGroups);

    return Column(
      children: [
        // Search bar at the top
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

        // Status filter chips (always visible)
        _buildStatusFilterChips(),

        // Orders list grouped by linking or empty state
        Expanded(
          child: filteredLinkingGroups.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? (_selectedStatus == null
                            ? 'No orders found'
                            : 'No orders with status: ${_selectedStatus!.name}')
                        : 'No companies found matching "$_searchQuery"',
                  ),
                )
              : ListView.builder(
                  itemCount: filteredLinkingGroups.length,
                  itemBuilder: (context, index) {
                    final group = filteredLinkingGroups[index];
                    return _buildLinkingGroup(group);
                  },
                ),
        ),
      ],
    );
  }

  // Build status filter chips
  Widget _buildStatusFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            _buildStatusChip(null, 'All'),
            const SizedBox(width: 8),
            ...OrderStatus.values.map(
              (status) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildStatusChip(status, status.name),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build a status filter chip
  Widget _buildStatusChip(OrderStatus? status, String label) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
      },
    );
  }

  // Build a linking group with its orders
  Widget _buildLinkingGroup(_LinkingOrdersGroup group) {
    final company = group.company;
    final companyName = company?.name ?? 'Company #${widget.companyIdToLoad(group.linking)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linking header (tappable to open linking details)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LinkingDetailView(
                      linking: group.linking,
                      companyIdToLoad: widget.companyIdToLoad(group.linking),
                      showAcceptRejectButtons: false,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Company logo
                    if (company?.logoUrl != null && company!.logoUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Image.network(
                            company.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderLogo(),
                          ),
                        ),
                      )
                    else
                      _buildPlaceholderLogo(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Linking #${group.linking.linkingId ?? 'N/A'}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            companyName,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),

          // Orders list
          if (group.orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No orders'),
            )
          else
            ...group.orders.map((order) => _buildOrderCard(order)),
        ],
      ),
    );
  }

  // Build an order card
  Widget _buildOrderCard(Order order) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute<bool>(
            builder: (_) => OrderDetailView(
              order: order,
              companyIdToLoad: widget.companyIdToLoad,
            ),
          ),
        );

        // Refresh if needed
        if (result == true && mounted) {
          _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.orderId}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(order.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Chip(
                  label: Text(order.status.name.toUpperCase()),
                  labelStyle: const TextStyle(fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.totalPrice} ₸',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
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

  // Build placeholder logo
  Widget _buildPlaceholderLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.business, size: 24, color: Colors.grey),
    );
  }
}

// Helper class to group orders by linking
class _LinkingOrdersGroup {
  const _LinkingOrdersGroup({
    required this.linking,
    required this.orders,
    this.company,
  });

  final Linking linking;
  final List<Order> orders;
  final Company? company;
}

