import 'dart:developer';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../models/order.dart';

/// Service handling CRUD operations for orders.
class OrderService {
  OrderService({required this.config, Dio? dioClient})
    : _dio =
          dioClient ??
          Dio(
            BaseOptions(
              baseUrl: config.apiRoot,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: const <String, Object?>{
                Headers.acceptHeader: 'application/json',
                Headers.contentTypeHeader: 'application/json',
              },
            ),
          );

  final AppConfig config;
  final Dio _dio;

  static const String _ordersPath = 'orders/';

  /// Get all orders for the current user's company.
  Future<List<Order>> getAllOrders() async {
    log('OrderService -> GET $_ordersPath');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(_ordersPath);
      final dynamic body = response.data;

      // API returns array of orders
      if (body is List) {
        return body
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(Order.fromJson)
            .toList();
      }

      // Handle wrapped response
      if (body is Map && body['orders'] is List) {
        return (body['orders'] as List)
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(Order.fromJson)
            .toList();
      }

      throw const FormatException('Unexpected orders list payload.');
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Get orders by linking ID.
  Future<List<Order>> getOrdersByLinking({required int linkingId}) async {
    final String path = '${_ordersPath}linking/$linkingId';
    log('OrderService -> GET $path');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(path);
      final dynamic body = response.data;

      // API returns array of orders
      if (body is List) {
        return body
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(Order.fromJson)
            .toList();
      }

      throw const FormatException('Unexpected orders list payload.');
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Get a single order by ID.
  Future<Order> getOrder({required int orderId}) async {
    final String path = '$_ordersPath$orderId';
    log('OrderService -> GET $path');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(path);
      return _parseOrderResponse(response);
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Create a new order.
  Future<void> createOrder({
    required int supplierCompanyId,
    required OrderCreateRequest request,
  }) async {
    log('OrderService -> POST $_ordersPath?supplier_company_id=$supplierCompanyId');

    try {
      await _dio.post<dynamic>(
        _ordersPath,
        data: request.toJson(),
        queryParameters: <String, dynamic>{
          'supplier_company_id': supplierCompanyId,
        },
      );
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Update order status.
  Future<void> updateOrderStatus({
    required int orderId,
    required OrderStatus status,
  }) async {
    final String path = '${_ordersPath}$orderId/status';
    log('OrderService -> PATCH $path?status=${status.apiValue}');

    try {
      await _dio.patch<dynamic>(
        path,
        queryParameters: <String, dynamic>{
          'status': status.apiValue,
        },
      );
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Convert backend response to an Order instance.
  Order _parseOrderResponse(Response<dynamic> response) {
    final dynamic body = response.data;

    // Accept either a direct order map or a wrapped { "order": { ... } }.
    if (body is Map && body['order'] is Map) {
      final Map<String, dynamic> wrapped =
          Map<String, dynamic>.from(body['order'] as Map);
      return Order.fromJson(wrapped);
    }
    if (body is Map<String, dynamic>) {
      return Order.fromJson(body);
    }
    if (body is Map<dynamic, dynamic>) {
      return Order.fromJson(Map<String, dynamic>.from(body));
    }

    throw const FormatException('Unexpected order payload format.');
  }

  Never _logAndRethrow(DioException error, StackTrace stackTrace) {
    log(
      'OrderService DioException: ${error.type} - ${error.message}',
      error: error,
      stackTrace: stackTrace,
    );

    Error.throwWithStackTrace(
      Exception(error.message ?? 'Network error while processing order'),
      stackTrace,
    );
  }
}

