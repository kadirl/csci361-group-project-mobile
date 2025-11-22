import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';
import '../storage/cart_storage.dart';
import 'auth_provider.dart';

// Cart state containing list of cart items
class CartState {
  const CartState({
    this.items = const [],
    this.isLoading = false,
  });

  final List<CartItem> items;
  final bool isLoading;

  // Get total number of items in cart
  int get totalItems => items.fold(0, (sum, item) => sum + item.count);

  // Check if cart is empty
  bool get isEmpty => items.isEmpty;

  // Get item count for a specific product
  int getItemCount(int productId) {
    final item = items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => const CartItem(productId: -1, count: 0),
    );
    return item.productId == -1 ? 0 : item.count;
  }

  // Check if product is in cart
  bool containsProduct(int productId) {
    return items.any((item) => item.productId == productId);
  }

  // CopyWith method for immutability
  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Cart notifier - manages cart state and persistence
class CartNotifier extends Notifier<CartState> {
  late final CartStorage _cartStorage = ref.read(cartStorageProvider);

  @override
  CartState build() {
    // Load cart from storage on initialization (fire and forget)
    Future.microtask(() => _loadCartFromStorage());
    return const CartState();
  }

  // Load cart from local storage
  Future<void> _loadCartFromStorage() async {
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user == null) {
      // No user logged in, return empty cart
      state = const CartState();
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final items = await _cartStorage.loadCart(user.email);
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      // If loading fails, start with empty cart
      state = const CartState();
    }
  }

  // Save cart to local storage
  Future<void> _saveCartToStorage() async {
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user == null) {
      return;
    }

    try {
      await _cartStorage.saveCart(user.email, state.items);
    } catch (e) {
      // Silently fail - cart will be saved on next operation
    }
  }

  // Add item to cart or increment count if already exists
  // Validates against product stock quantity and minimum order
  Future<void> addItem(Product product, {int count = 1}) async {
    // Validate against stock quantity
    if (count > product.stockQuantity) {
      throw Exception(
        'Cannot add more than available stock (${product.stockQuantity})',
      );
    }

    // Validate against minimum order
    if (count < product.minimumOrder) {
      throw Exception(
        'Minimum order quantity is ${product.minimumOrder}',
      );
    }

    final currentItems = List<CartItem>.from(state.items);
    final existingIndex = currentItems.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex != -1) {
      // Item already exists, update count
      final existingItem = currentItems[existingIndex];
      final newCount = existingItem.count + count;

      // Validate new total count against stock
      if (newCount > product.stockQuantity) {
        throw Exception(
          'Total quantity exceeds available stock (${product.stockQuantity})',
        );
      }

      currentItems[existingIndex] = existingItem.copyWith(count: newCount);
    } else {
      // New item, add to cart
      if (product.id == null) {
        throw Exception('Product ID is required');
      }
      currentItems.add(CartItem(productId: product.id!, count: count));
    }

    state = state.copyWith(items: currentItems);
    await _saveCartToStorage();
  }

  // Update item quantity
  // Validates against product stock quantity and minimum order
  Future<void> updateQuantity(int productId, int newCount, Product product) async {
    // Validate against stock quantity
    if (newCount > product.stockQuantity) {
      throw Exception(
        'Cannot set quantity higher than available stock (${product.stockQuantity})',
      );
    }

    // Validate against minimum order if count > 0
    if (newCount > 0 && newCount < product.minimumOrder) {
      throw Exception(
        'Minimum order quantity is ${product.minimumOrder}',
      );
    }

    final currentItems = List<CartItem>.from(state.items);
    final existingIndex = currentItems.indexWhere(
      (item) => item.productId == productId,
    );

    if (existingIndex == -1) {
      throw Exception('Product not found in cart');
    }

    if (newCount <= 0) {
      // Remove item if count is 0 or less
      currentItems.removeAt(existingIndex);
    } else {
      // Update count
      currentItems[existingIndex] = currentItems[existingIndex].copyWith(
        count: newCount,
      );
    }

    state = state.copyWith(items: currentItems);
    await _saveCartToStorage();
  }

  // Remove item from cart
  Future<void> removeItem(int productId) async {
    final currentItems = List<CartItem>.from(state.items);
    currentItems.removeWhere((item) => item.productId == productId);

    state = state.copyWith(items: currentItems);
    await _saveCartToStorage();
  }

  // Clear all items from cart
  Future<void> clearCart() async {
    final authState = ref.read(authProvider);
    final user = authState.user;

    state = const CartState();

    if (user != null) {
      await _cartStorage.clearCart(user.email);
    }
  }

  // Reload cart from storage (useful after user login/logout)
  Future<void> reloadCart() async {
    await _loadCartFromStorage();
  }
}

// Provider for cart notifier
final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});

