import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart'; // Import Dio
import 'package:customer_app/src/api/api_client.dart'; // Import ApiClient
import 'package:customer_app/src/models/cart_item_model.dart';
import 'package:customer_app/src/models/product_model.dart';

class CartProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient(); // ApiClient instance
  final Map<String, CartItemModel> _items = {};
  double _deliveryFee = 0.0; // Delivery Fee

  Map<String, CartItemModel> get items => {..._items}; // Return a copy
  int get itemCount => _items.length;
  double get deliveryFee => _deliveryFee; // Delivery Fee Getter

  String _generateKey(int productId, String unitType) {
    return '${productId}_$unitType';
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      double price = 0.0;
      switch (cartItem.unitType) {
        case 'Pack':
          price = double.tryParse(cartItem.product.packPrice ?? '0') ?? 0.0;
          break;
        case 'Single':
          // Priority: pricePerPiece -> stripPrice -> base price (as fallback)
          price = double.tryParse(cartItem.product.pricePerPiece ?? '') ?? 
                  double.tryParse(cartItem.product.stripPrice ?? '') ?? 
                  double.tryParse(cartItem.product.price) ?? 0.0;
          break;
        case 'Default':
        default:
          price = double.tryParse(cartItem.product.price) ?? 0.0;
      }
      total += price * cartItem.quantity;
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

  void addItem(ProductModel product, [int quantity = 1, String unitType = 'Default']) {
    final key = _generateKey(product.id, unitType);
    if (_items.containsKey(key)) {
      _items.update(
        key,
        (existingItem) => CartItemModel(
          product: existingItem.product,
          quantity: existingItem.quantity + quantity,
          unitType: unitType,
        ),
      );
    } else {
      _items.putIfAbsent(
        key,
        () => CartItemModel(product: product, quantity: quantity, unitType: unitType),
      );
    }
    notifyListeners();
  }

  void removeItem(int productId, [String unitType = 'Default']) {
    final key = _generateKey(productId, unitType);
    _items.remove(key);
    notifyListeners();
  }

  void updateItemQuantity(int productId, int newQuantity, [String unitType = 'Default']) {
    final key = _generateKey(productId, unitType);
    if (_items.containsKey(key)) {
      if (newQuantity <= 0) {
        _items.remove(key);
      } else {
        _items.update(
          key,
          (existingItem) => CartItemModel(
            product: existingItem.product,
            quantity: newQuantity,
            unitType: unitType,
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
