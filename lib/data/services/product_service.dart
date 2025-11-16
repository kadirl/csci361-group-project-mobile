import 'dart:developer';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../models/product.dart';

// Service handling CRUD operations for products.
class ProductService {
  ProductService({required this.config, Dio? dioClient})
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

  static const String _productsPath = 'products/';

  // Retrieve all products (protected endpoint).
  Future<List<Product>> listProducts() async {
    log('ProductService -> GET $_productsPath');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(_productsPath);
      final dynamic body = response.data;

      // API returns: { "products": [ { ...product... }, ... ] }
      if (body is Map) {
        final dynamic productsNode = body['products'];
        if (productsNode is List) {
          return productsNode
              .whereType<Map<dynamic, dynamic>>()
              .map((e) => Map<String, dynamic>.from(e))
              .map(Product.fromJson)
              .toList();
        }
      }

      throw const FormatException('Unexpected products list payload.');
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  // Add a product (protected endpoint).
  Future<Product> addProduct({required ProductRequest request}) async {
    log('ProductService -> POST $_productsPath');

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        _productsPath,
        data: request.toJson(),
      );
      return _parseProductResponse(response);
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  // Update a product by id (protected endpoint).
  Future<Product> updateProduct({
    required int productId,
    required ProductRequest request,
  }) async {
    final String path = 'products/$productId';
    log('ProductService -> PUT $path');

    try {
      final Response<dynamic> response = await _dio.put<dynamic>(
        path,
        data: request.toJson(),
      );
      return _parseProductResponse(response);
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  // Delete a product by id (protected endpoint).
  Future<void> deleteProduct({required int productId}) async {
    final String path = 'products/$productId';
    log('ProductService -> DELETE $path');

    try {
      await _dio.delete<dynamic>(path);
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  // Convert backend response to a Product instance.
  Product _parseProductResponse(Response<dynamic> response) {
    final dynamic body = response.data;

    // Accept either a direct product map or a wrapped { "product": { ... } }.
    if (body is Map && body['product'] is Map) {
      final Map<String, dynamic> wrapped =
          Map<String, dynamic>.from(body['product'] as Map);
      return Product.fromJson(wrapped);
    }
    if (body is Map<String, dynamic>) {
      return Product.fromJson(body);
    }
    if (body is Map<dynamic, dynamic>) {
      return Product.fromJson(Map<String, dynamic>.from(body));
    }

    throw const FormatException('Unexpected product payload format.');
  }

  Never _logAndRethrow(DioException error, StackTrace stackTrace) {
    log(
      'ProductService DioException: ${error.type} - ${error.message}',
      error: error,
      stackTrace: stackTrace,
    );

    Error.throwWithStackTrace(
      Exception(error.message ?? 'Network error while processing product'),
      stackTrace,
    );
  }
}


