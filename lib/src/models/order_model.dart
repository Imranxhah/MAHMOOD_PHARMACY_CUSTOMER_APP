import 'order_item_model.dart';

class OrderModel {
  final int id;
  final int user; // User ID
  final String status;
  final String orderType;
  final String totalAmount;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  final String shippingAddress;
  final String contactNumber;

  OrderModel({
    required this.id,
    required this.user,
    required this.status,
    required this.orderType,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
    required this.shippingAddress,
    required this.contactNumber,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Handle 'user' field which might be an int (ID) or a Map (User object)
    int userId;
    if (json['user'] is int) {
      userId = json['user'];
    } else if (json['user'] is Map) {
      userId = json['user']['id'];
    } else {
      userId = 0; // Fallback or throw error
    }

    return OrderModel(
      id: json['id'],
      user: userId,
      status: json['status'],
      orderType: json['order_type'] ?? 'Normal',
      totalAmount: json['total_amount'].toString(),
      createdAt: DateTime.parse(json['created_at']),
      items: (json['items'] as List)
          .map((itemJson) => OrderItemModel.fromJson(itemJson))
          .toList(),
      shippingAddress: json['shipping_address'] ?? 'N/A',
      contactNumber: json['contact_number'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'status': status,
      'order_type': orderType,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'shipping_address': shippingAddress,
      'contact_number': contactNumber,
    };
  }
}
