class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double priceAtPurchase;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.priceAtPurchase,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['product'] is int ? json['product'] : (json['product'] != null ? json['product']['id'] : 0),
      productName: json['product_name'] ?? 'Unknown Product',
      productImage: json['product_image'],
      quantity: json['quantity'] ?? 0,
      priceAtPurchase: double.tryParse(json['price_at_purchase'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': productId,
      'product_name': productName,
      'product_image': productImage,
      'quantity': quantity,
      'price_at_purchase': priceAtPurchase,
    };
  }
}

class Branch {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final String? timing;
  final bool? isActive;
  final String? image;

  Branch({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
    this.timing,
    this.isActive,
    this.image,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timing: json['timing'],
      isActive: json['is_active'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'timing': timing,
      'is_active': isActive,
      'image': image,
    };
  }
}

class Order {
  final int id;
  final String status;
  final String paymentMethod;
  final double totalAmount;
  final String createdAt;
  final String? shippingAddress;
  final String? contactNumber;
  final String? orderType;
  final List<OrderItem> items;
  final Branch? branch;

  Order({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.totalAmount,
    required this.createdAt,
    this.shippingAddress,
    this.contactNumber,
    this.orderType,
    required this.items,
    this.branch,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<OrderItem> items =
        itemsList.map((i) => OrderItem.fromJson(i)).toList();
    
    return Order(
      id: json['id'],
      status: json['status'],
      paymentMethod: json['payment_method'] ?? 'COD',
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      createdAt: json['created_at'],
      shippingAddress: json['shipping_address'],
      contactNumber: json['contact_number'],
      orderType: json['order_type'],
      items: items,
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'payment_method': paymentMethod,
      'total_amount': totalAmount,
      'created_at': createdAt,
      'shipping_address': shippingAddress,
      'contact_number': contactNumber,
      'order_type': orderType,
      'items': items.map((i) => i.toJson()).toList(),
      'branch': branch?.toJson(),
    };
  }

  Order copyWith({
    int? id,
    String? status,
    String? paymentMethod,
    double? totalAmount,
    String? createdAt,
    String? shippingAddress,
    String? contactNumber,
    String? orderType,
    List<OrderItem>? items,
    Branch? branch,
  }) {
    return Order(
      id: id ?? this.id,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      contactNumber: contactNumber ?? this.contactNumber,
      orderType: orderType ?? this.orderType,
      items: items ?? this.items,
      branch: branch ?? this.branch,
    );
  }
}