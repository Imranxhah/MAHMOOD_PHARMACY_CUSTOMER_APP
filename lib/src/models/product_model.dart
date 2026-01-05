import '../constants/api_constants.dart';

class ProductModel {
  final int id;
  final int category; // Added category ID
  final String categoryName;
  final String name;
  final String? genericName;
  final String description;
  final String price;
  final int stock;
  final String? image;
  final bool isActive;
  bool isFavorite;

  ProductModel({
    required this.id,
    required this.category, // Added category ID
    required this.categoryName,
    required this.name,
    this.genericName,
    required this.description,
    required this.price,
    required this.stock,
    this.image,
    required this.isActive,
    required this.isFavorite,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String? imageUrl = json['image'];
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      if (imageUrl.startsWith('/')) {
        imageUrl = '${ApiConstants.mediaBaseUrl}$imageUrl';
      } else {
        imageUrl = '${ApiConstants.mediaBaseUrl}/$imageUrl';
      }
    }

    return ProductModel(
      id: json['id'],
      category: json['category'] ?? 0, // Map category ID
      categoryName: json['category_name'] ?? '',
      name: json['name'],
      genericName: json['generic_name']?.toString().trim(),
      description: json['description'] ?? '',
      price: json['price'].toString(),
      stock: json['stock'] ?? 0,
      image: imageUrl,
      isActive: json['is_active'] ?? true,
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category, // Add category to JSON
      'category_name': categoryName,
      'name': name,
      'generic_name': genericName,
      'description': description,
      'price': price,
      'stock': stock,
      'image': image,
      'is_active': isActive,
      'is_favorite': isFavorite,
    };
  }
}
