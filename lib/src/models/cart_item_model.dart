import 'package:customer_app/src/models/product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({required this.product, this.quantity = 1});

  // Helper method to convert to the format expected by the API for order placement
  Map<String, dynamic> toJsonApi() {
    return {'product_id': product.id, 'quantity': quantity};
  }
}
