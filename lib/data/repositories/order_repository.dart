import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/authorized_dio_provider.dart';
import '../models/order.dart';
import '../services/order_service.dart';

/// Repository that exposes order operations to the app.
class OrderRepository {
  OrderRepository(this._service);

  final OrderService _service;

  /// Get all orders for the current user's company.
  Future<List<Order>> getAllOrders() {
    return _service.getAllOrders();
  }

  /// Get orders by linking ID.
  Future<List<Order>> getOrdersByLinking({required int linkingId}) {
    return _service.getOrdersByLinking(linkingId: linkingId);
  }

  /// Get a single order by ID.
  Future<Order> getOrder({required int orderId}) {
    return _service.getOrder(orderId: orderId);
  }

  /// Create a new order.
  Future<void> createOrder({
    required int supplierCompanyId,
    required OrderCreateRequest request,
  }) {
    return _service.createOrder(
      supplierCompanyId: supplierCompanyId,
      request: request,
    );
  }

  /// Update order status.
  Future<void> updateOrderStatus({
    required int orderId,
    required OrderStatus status,
  }) {
    return _service.updateOrderStatus(
      orderId: orderId,
      status: status,
    );
  }
}

/// Provider wiring OrderService with authorized Dio instance.
final orderServiceProvider = Provider<OrderService>((ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  final Dio dio = ref.watch(authorizedDioProvider);

  return OrderService(config: config, dioClient: dio);
});

/// Provider that exposes OrderRepository.
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final OrderService service = ref.watch(orderServiceProvider);
  return OrderRepository(service);
});

