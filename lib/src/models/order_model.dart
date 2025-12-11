import 'order_item_model.dart';

class OrderModel {
  final int id;
  final int user; // User ID
  final String status;
  final String totalAmount;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  final String shippingAddress;
  final String contactNumber;

  OrderModel({
    required this.id,
    required this.user,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
    required this.shippingAddress,
    required this.contactNumber,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      user: json['user'],
      status: json['status'],
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
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'shipping_address': shippingAddress,
      'contact_number': contactNumber,
    };
  }
}
