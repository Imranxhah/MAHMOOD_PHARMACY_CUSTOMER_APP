import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart'; // Import Dio
import 'package:customer_app/src/api/api_client.dart'; // Import ApiClient
import 'package:customer_app/src/models/cart_item_model.dart';
import 'package:customer_app/src/models/product_model.dart';

class CartProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient(); // ApiClient instance
  final Map<int, CartItemModel> _items = {};
  double _deliveryFee = 0.0; // Delivery Fee

  Map<int, CartItemModel> get items => {..._items}; // Return a copy
  int get itemCount => _items.length;
  double get deliveryFee => _deliveryFee; // Delivery Fee Getter

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += double.parse(cartItem.product.price) * cartItem.quantity;
    });
    return total;
  }

  Future<void> fetchDeliveryCharges() async {
    try {
      final response = await _apiClient.getDeliveryCharges();
      if (response.statusCode == 200) {
        _deliveryFee = double.tryParse(response.data['amount'].toString()) ?? 0.0;
      }
    } catch (e) {
      debugPrint("Failed to fetch delivery charges: $e");
      _deliveryFee = 0.0; // Default to 0.0 on error
    } finally {
      notifyListeners();
    }
  }

  void addItem(ProductModel product, [int quantity = 1]) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existingItem) => CartItemModel(
          product: existingItem.product,
          quantity: existingItem.quantity + quantity,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItemModel(product: product, quantity: quantity),
      );
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void updateItemQuantity(int productId, int newQuantity) {
    if (_items.containsKey(productId)) {
      if (newQuantity <= 0) {
        _items.remove(productId);
      } else {
        _items.update(
          productId,
          (existingItem) => CartItemModel(
            product: existingItem.product,
            quantity: newQuantity,
          ),
        );
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Method to convert cart items to the API format
  List<Map<String, dynamic>> toApiCartItems() {
    return _items.values.map((item) => item.toJsonApi()).toList();
  }
}
