import 'package:swe_mobile/data/models/order.dart';
import 'package:swe_mobile/data/models/product.dart';

/// Aggregated data for the Supplier Dashboard.
class DashboardData {
  DashboardData({
    required this.totalRevenue,
    required this.ordersTodayCount,
    required this.pendingOrdersCount,
    required this.lowStockCount,
    required this.activeClientsCount,
    required this.recentOrders,
    required this.lowStockProducts,
    required this.revenueTrend,
    required this.orderStatusDistribution,
  });

  final int totalRevenue;
  final int ordersTodayCount;
  final int pendingOrdersCount;
  final int lowStockCount;
  final int activeClientsCount;
  final List<Order> recentOrders;
  final List<Product> lowStockProducts;
  
  /// Date -> Revenue (in cents/units)
  final Map<DateTime, int> revenueTrend;
  
  /// Status -> Count
  final Map<OrderStatus, int> orderStatusDistribution;

  factory DashboardData.empty() {
    return DashboardData(
      totalRevenue: 0,
      ordersTodayCount: 0,
      pendingOrdersCount: 0,
      lowStockCount: 0,
      activeClientsCount: 0,
      recentOrders: [],
      lowStockProducts: [],
      revenueTrend: {},
      orderStatusDistribution: {},
    );
  }
}
