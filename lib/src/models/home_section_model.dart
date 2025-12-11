import 'package:customer_app/src/models/category_model.dart';
import 'package:customer_app/src/models/product_model.dart';

class HomeSectionModel {
  final CategoryModel category;
  final List<ProductModel> products;

  HomeSectionModel({
    required this.category,
    required this.products,
  });

  factory HomeSectionModel.fromJson(Map<String, dynamic> json) {
    return HomeSectionModel(
      category: CategoryModel.fromJson(json['category']),
      products: (json['products'] as List<dynamic>)
          .map((item) => ProductModel.fromJson(item))
          .toList(),
    );
  }
}
