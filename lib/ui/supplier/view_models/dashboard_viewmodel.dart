import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swe_mobile/core/providers/company_profile_provider.dart';
import 'package:swe_mobile/data/models/linking.dart';
import 'package:swe_mobile/data/models/order.dart';
import 'package:swe_mobile/data/models/product.dart';
import 'package:swe_mobile/data/repositories/linking_repository.dart';
import 'package:swe_mobile/data/repositories/order_repository.dart';
import 'package:swe_mobile/data/repositories/product_repository.dart';
import 'package:swe_mobile/ui/supplier/models/dashboard_data.dart';

class DashboardViewModel extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    return _fetchData();
  }

  Future<DashboardData> _fetchData() async {
    print('DEBUG: DashboardViewModel _fetchData started');
    final company = await ref.watch(companyProfileProvider.future);
    if (company == null || company.id == null) {
      print('DEBUG: Company profile is null or has no ID. Returning empty data.');
      return DashboardData.empty();
    }
    final companyId = company.id!;
    print('DEBUG: Fetching dashboard data for company $companyId');

    print('DEBUG: About to read repositories...');
    final orderRepo = ref.read(orderRepositoryProvider);
    print('DEBUG: orderRepo = $orderRepo');
    
    final productRepo = ref.read(productRepositoryProvider);
    print('DEBUG: productRepo = $productRepo');
    
    final linkingRepo = ref.read(linkingRepositoryProvider);
    print('DEBUG: linkingRepo = $linkingRepo');

    // Fetch data in parallel with error handling
    List<Order> orders = [];
    List<Product> products = [];
    List<Linking> linkings = [];
    
    print('DEBUG: About to fetch orders...');
    try {
      print('DEBUG: Calling orderRepo.getAllOrders()...');
      orders = await orderRepo.getAllOrders();
      print('DEBUG: Successfully fetched ${orders.length} orders');
    } catch (e, stack) {
      print('DEBUG: ERROR fetching orders: $e');
      print('DEBUG: Stack trace: $stack');
    }
    
    try {
      print('DEBUG: Fetching products for company $companyId...');
      products = await productRepo.listProducts(companyId: companyId);
      print('DEBUG: Successfully fetched ${products.length} products');
    } catch (e, stack) {
      print('DEBUG: ERROR fetching products: $e');
      print('DEBUG: Stack trace: $stack');
    }
    
    try {
      print('DEBUG: Fetching linkings for company $companyId...');
      linkings = await linkingRepo.getLinkingsByCompany(companyId: companyId);
      print('DEBUG: Successfully fetched ${linkings.length} linkings');
    } catch (e, stack) {
      print('DEBUG: ERROR fetching linkings: $e');
      print('DEBUG: Stack trace: $stack');
    }
    
    print('DEBUG: Fetched ${orders.length} orders, ${products.length} products, ${linkings.length} linkings');

    // Deduplicate orders by orderId to fix double-counting issue
    final Map<int, Order> uniqueOrdersMap = {};
    for (final order in orders) {
      uniqueOrdersMap[order.orderId] = order;
    }
    final List<Order> uniqueOrders = uniqueOrdersMap.values.toList();
    
    print('DEBUG: After deduplication: ${uniqueOrders.length} unique orders (removed ${orders.length - uniqueOrders.length} duplicates)');

    // Process Orders
    int totalRevenue = 0;
    int ordersToday = 0;
    int pendingOrders = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final Map<DateTime, int> revenueTrend = {};
    final Map<OrderStatus, int> statusDist = {};

    for (final order in uniqueOrders) {
      // Revenue (Completed, Processing, Shipping)
      if (order.status == OrderStatus.completed || 
          order.status == OrderStatus.processing || 
          order.status == OrderStatus.shipping) {
         print('DEBUG: Adding order ${order.orderId} to revenue. Status: ${order.status}, Price: ${order.totalPrice}');
         totalRevenue += order.totalPrice;
         
         // Trend
         if (order.createdAt.isNotEmpty) {
             try {
                 final date = DateTime.parse(order.createdAt);
                 final dayKey = DateTime(date.year, date.month, date.day);
                 revenueTrend[dayKey] = (revenueTrend[dayKey] ?? 0) + order.totalPrice;
             } catch (_) {}
         }
      } else {
         print('DEBUG: Skipping order ${order.orderId} for revenue. Status: ${order.status}, Price: ${order.totalPrice}');
      }

      // Orders Today - count all orders created on or after today's date
      if (order.createdAt.isNotEmpty) {
          try {
              final date = DateTime.parse(order.createdAt);
              // Check if order was created today (on or after 00:00:00 today)
              if (!date.isBefore(today)) {
                  ordersToday++;
              }
          } catch (_) {}
      }

      // Pending
      if (order.status == OrderStatus.created) {
          pendingOrders++;
      }
      
      // Status Distribution
      statusDist[order.status] = (statusDist[order.status] ?? 0) + 1;
    }

    // Process Products (Low Stock)
    int lowStockCount = 0;
    final List<Product> lowStockList = [];
    for (final product in products) {
        if (product.stockQuantity <= product.threshold) {
            lowStockCount++;
            lowStockList.add(product);
        }
    }
    lowStockList.sort((a, b) => (a.stockQuantity - a.threshold).compareTo(b.stockQuantity - b.threshold));

    // Active Clients
    final activeClients = linkings.where((l) => l.status == LinkingStatus.accepted).length;

    // Recent Orders
    final recentOrders = List<Order>.from(uniqueOrders);
    recentOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return DashboardData(
      totalRevenue: totalRevenue,
      ordersTodayCount: ordersToday,
      pendingOrdersCount: pendingOrders,
      lowStockCount: lowStockCount,
      activeClientsCount: activeClients,
      recentOrders: recentOrders.take(5).toList(),
      lowStockProducts: lowStockList.take(5).toList(),
      revenueTrend: revenueTrend,
      orderStatusDistribution: statusDist,
    );
  }
  
  Future<void> refresh() async {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => _fetchData());
  }
}

final dashboardViewModelProvider = AsyncNotifierProvider<DashboardViewModel, DashboardData>(DashboardViewModel.new);
