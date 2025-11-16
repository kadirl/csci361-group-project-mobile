import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/authorized_dio_provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';

// Repository that exposes product operations to the app.
class ProductRepository {
  ProductRepository(this._service);

  final ProductService _service;

  // List available products.
  Future<List<Product>> listProducts({required int companyId}) {
    return _service.listProducts(companyId: companyId);
  }

  // Add a new product.
  Future<Product> addProduct({required ProductRequest request}) {
    return _service.addProduct(request: request);
  }

  // Update an existing product by id.
  Future<Product> updateProduct({
    required int productId,
    required ProductRequest request,
  }) {
    return _service.updateProduct(productId: productId, request: request);
  }

  // Remove a product by id.
  Future<void> deleteProduct({required int productId}) {
    return _service.deleteProduct(productId: productId);
  }
}

// Provider wiring ProductService with authorized Dio instance.
final productServiceProvider = Provider<ProductService>((ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  final Dio dio = ref.watch(authorizedDioProvider);

  return ProductService(config: config, dioClient: dio);
});

// Provider that exposes ProductRepository.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final ProductService service = ref.watch(productServiceProvider);
  return ProductRepository(service);
});



