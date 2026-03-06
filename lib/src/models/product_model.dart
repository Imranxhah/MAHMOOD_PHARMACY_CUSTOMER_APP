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
  final int? stripsInPack;
  final int? tabletsInStrip;
  final String? packPrice;
  final String? stripPrice;
  final String? pricePerPiece; // Added this
  final String? manufacturer;

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
    this.stripsInPack,
    this.tabletsInStrip,
    this.packPrice,
    this.stripPrice,
    this.pricePerPiece, // Added this
    this.manufacturer,
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
      stripsInPack: json['strips_in_pack'],
      tabletsInStrip: json['tablets_in_strip'],
      packPrice: json['pack_price']?.toString(),
      stripPrice: json['strip_price']?.toString(),
      pricePerPiece: json['price_per_piece']?.toString(), // Map this
      manufacturer: json['manufacturer'],
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
      'strips_in_pack': stripsInPack,
      'tablets_in_strip': tabletsInStrip,
      'pack_price': packPrice,
      'strip_price': stripPrice,
      'price_per_piece': pricePerPiece, // Add this
      'manufacturer': manufacturer,
    };
  }
}
