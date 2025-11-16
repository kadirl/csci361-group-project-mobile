import 'package:flutter/foundation.dart';

// Immutable representation of a product entity used across the app.
@immutable
class Product {
  const Product({
    required this.name,
    required this.description,
    required this.pictureUrls,
    required this.stockQuantity,
    required this.retailPrice,
    required this.threshold,
    required this.bulkPrice,
    required this.minimumOrder,
    required this.unit,
    this.companyId,
    this.id,
    this.additionalData = const <String, dynamic>{},
  });

  // Identifier may be absent on creation responses.
  final int? id;
  final int? companyId;

  // Basic product attributes.
  final String name;
  final String description;
  final List<String> pictureUrls;
  final int stockQuantity;
  final int retailPrice;
  final int threshold;
  final int bulkPrice;
  final int minimumOrder;
  final String unit;

  // Preserve unmodeled backend fields for forward compatibility.
  final Map<String, dynamic> additionalData;

  // Build a Product from backend payload.
  factory Product.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> extra = Map<String, dynamic>.from(json);

    return Product(
      // Some endpoints return 'product_id' instead of 'id'.
      id: (json['id'] as int?) ?? (json['product_id'] as int?),
      companyId: json['company_id'] as int?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      pictureUrls: (json['picture_url'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      retailPrice: (json['retail_price'] as num?)?.toInt() ?? 0,
      threshold: (json['threshold'] as num?)?.toInt() ?? 0,
      bulkPrice: (json['bulk_price'] as num?)?.toInt() ?? 0,
      minimumOrder: (json['minimum_order'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? '',
      additionalData: extra,
    );
  }
}

// Request DTO used for adding or updating a product.
@immutable
class ProductRequest {
  const ProductRequest({
    required this.name,
    required this.description,
    required this.pictureUrls,
    required this.stockQuantity,
    required this.retailPrice,
    required this.threshold,
    required this.bulkPrice,
    required this.minimumOrder,
    required this.unit,
  });

  final String name;
  final String description;
  final List<String> pictureUrls;
  final int stockQuantity;
  final int retailPrice;
  final int threshold;
  final int bulkPrice;
  final int minimumOrder;
  final String unit;

  // Convert to API payload according to ProductSchema.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'picture_url': pictureUrls,
      'stock_quantity': stockQuantity,
      'retail_price': retailPrice,
      'threshold': threshold,
      'bulk_price': bulkPrice,
      'minimum_order': minimumOrder,
      'unit': unit,
    };
  }
}


