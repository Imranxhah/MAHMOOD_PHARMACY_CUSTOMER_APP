class OrderItemModel {
  final String productId;
  final int quantity;
  final String name; // From nested product info
  final String price; // From nested product info

  OrderItemModel({
    required this.productId,
    required this.quantity,
    required this.name,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    var prodId = json['product_id'];
    String prodIdStr;
    if (prodId is Map) {
      prodIdStr = prodId['id'].toString();
    } else {
      prodIdStr = prodId.toString();
    }

    return OrderItemModel(
      productId: prodIdStr, // Ensure it's a string
      quantity: json['quantity'],
      name: json['name'] ?? 'Unknown Product',
      price: json['price'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'name': name,
      'price': price,
    };
  }
}
