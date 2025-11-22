import 'package:flutter/foundation.dart';

import 'product.dart';

/// Order status enum matching backend order statuses.
enum OrderStatus {
  created,
  processing,
  shipping,
  completed,
  rejected,
}

/// Parse a raw status string from backend into an OrderStatus enum.
OrderStatus parseOrderStatus(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'created':
      return OrderStatus.created;
    case 'processing':
      return OrderStatus.processing;
    case 'shipping':
      return OrderStatus.shipping;
    case 'completed':
      return OrderStatus.completed;
    case 'rejected':
      return OrderStatus.rejected;
    default:
      // Default to 'created' for null or unknown statuses instead of throwing
      print('WARNING: Unknown order status "$raw", defaulting to "created"');
      return OrderStatus.created;
  }
}

/// Extension to convert OrderStatus to API string value.
extension OrderStatusX on OrderStatus {
  String get apiValue => name;
}

/// Immutable representation of an order product item.
@immutable
class OrderProduct {
  const OrderProduct({
    required this.productId,
    required this.quantity,
    this.product,
    this.pricePerUnit,
    this.subtotal,
  });

  final int productId;
  final int quantity;
  final Product? product; // Full product details if loaded
  final int? pricePerUnit; // Price used for this order item
  final int? subtotal; // Calculated subtotal (pricePerUnit * quantity)

  /// Build an instance from the backend payload.
  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      productId: json['product_id'] as int? ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      pricePerUnit: (json['price_per_unit'] as num?)?.toInt(),
      subtotal: (json['subtotal'] as num?)?.toInt(),
      product: json['product'] != null
          ? Product.fromJson(
              Map<String, dynamic>.from(json['product'] as Map),
            )
          : null,
    );
  }

  /// Convert to API payload.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'product_id': productId,
      'quantity': quantity,
    };
  }
}

/// Immutable representation of an order entity returned by the backend.
@immutable
class Order {
  const Order({
    required this.orderId,
    required this.linkingId,
    required this.consumerStaffId,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.products,
    this.additionalData = const <String, dynamic>{},
  });

  final int orderId;
  final int linkingId;
  final int consumerStaffId;
  final int totalPrice;
  final OrderStatus status;
  final String createdAt;
  final String updatedAt;
  final List<OrderProduct>? products; // Products may be included in detail response

  /// Store any unmodeled payload fields so we do not silently drop data.
  final Map<String, dynamic> additionalData;

  /// Build an instance from the backend payload.
  factory Order.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> extra = Map<String, dynamic>.from(json);

    // Parse products if present
    List<OrderProduct>? productsList;
    if (json['products'] != null && json['products'] is List) {
      productsList = (json['products'] as List)
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(OrderProduct.fromJson)
          .toList();
    }

    return Order(
      // Some endpoints return 'id' instead of 'order_id'
      orderId: (json['order_id'] as int?) ?? (json['id'] as int?) ?? 0,
      linkingId: json['linking_id'] as int? ?? 0,
      consumerStaffId: json['consumer_staff_id'] as int? ?? 0,
      // API returns 'order_total_price' or 'total_price'
      totalPrice: (json['order_total_price'] as num?)?.toInt() ?? 
                  (json['total_price'] as num?)?.toInt() ?? 0,
      // API returns 'order_status' or 'status'
      status: parseOrderStatus(
        (json['order_status'] as String?) ?? (json['status'] as String?)
      ),
      // API returns 'order_created_at' or 'created_at'
      createdAt: (json['order_created_at'] as String?) ?? 
                 (json['created_at'] as String?) ?? '',
      // API returns 'order_updated_at' or 'updated_at'
      updatedAt: (json['order_updated_at'] as String?) ?? 
                 (json['updated_at'] as String?) ?? '',
      products: productsList,
      additionalData: extra,
    );
  }
}

/// Request DTO used for creating an order.
@immutable
class OrderCreateRequest {
  const OrderCreateRequest({
    required this.products,
  });

  final List<OrderProductCreate> products;

  /// Convert to API payload.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'products': products.map((p) => p.toJson()).toList(),
    };
  }
}

/// Request DTO for order product creation.
@immutable
class OrderProductCreate {
  const OrderProductCreate({
    required this.productId,
    required this.quantity,
  });

  final int productId;
  final int quantity;

  /// Convert to API payload.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'product_id': productId,
      'quantity': quantity,
    };
  }
}

