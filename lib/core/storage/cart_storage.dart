import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/cart_item.dart';

// Storage service for cart data using SharedPreferences.
// Cart data is stored per user account using email as part of the storage key.
class CartStorage {
  // Generate storage key for a specific user's cart
  static String _storageKey(String userEmail) => 'cart_$userEmail';

  // Save cart items to local storage
  Future<void> saveCart(String userEmail, List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(userEmail);

    // Convert cart items to JSON array
    final jsonList = items.map((item) => item.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    await prefs.setString(key, jsonString);
  }

  // Load cart items from local storage
  Future<List<CartItem>> loadCart(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(userEmail);

    final jsonString = prefs.getString(key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => CartItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, return empty cart
      return [];
    }
  }

  // Clear cart for a specific user
  Future<void> clearCart(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(userEmail);
    await prefs.remove(key);
  }
}

// Provider for CartStorage instance
final cartStorageProvider = Provider<CartStorage>((ref) {
  return CartStorage();
});

