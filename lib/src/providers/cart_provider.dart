import 'package:flutter/foundation.dart';
import 'package:customer_app/src/models/cart_item_model.dart';
import 'package:customer_app/src/models/product_model.dart';

class CartProvider with ChangeNotifier {
  final Map<int, CartItemModel> _items = {};

  Map<int, CartItemModel> get items => {..._items}; // Return a copy
  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += double.parse(cartItem.product.price) * cartItem.quantity;
    });
    return total;
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
        () => CartItemModel(
          product: product,
          quantity: quantity,
        ),
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
    return _items.values
        .map((item) => item.toJsonApi())
        .toList();
  }
}
