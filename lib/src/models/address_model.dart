class AddressModel {
  final int id;
  final int user;
  final String address;
  final DateTime createdAt;

  AddressModel({
    required this.id,
    required this.user,
    required this.address,
    required this.createdAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      user: json['user'],
      address: json['address'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'address': address,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
