import 'package:flutter/foundation.dart';

// Immutable representation of a cart item containing product ID and quantity.
@immutable
class CartItem {
  const CartItem({
    required this.productId,
    required this.count,
  });

  final int productId;
  final int count;

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'product_id': productId,
      'count': count,
    };
  }

  // Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['product_id'] as int,
      count: json['count'] as int,
    );
  }

  // Create a copy with modified fields
  CartItem copyWith({
    int? productId,
    int? count,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      count: count ?? this.count,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          count == other.count;

  @override
  int get hashCode => productId.hashCode ^ count.hashCode;
}

