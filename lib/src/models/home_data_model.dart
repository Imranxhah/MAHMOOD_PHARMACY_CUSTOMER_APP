import 'package:customer_app/src/models/category_model.dart';
import 'package:customer_app/src/models/home_section_model.dart';

class HomeDataModel {
  final List<CategoryModel> categories;
  final List<HomeSectionModel> sections;

  HomeDataModel({required this.categories, required this.sections});

  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    return HomeDataModel(
      categories: (json['categories'] as List<dynamic>)
          .map((item) => CategoryModel.fromJson(item))
          .toList(),
      sections: (json['sections'] as List<dynamic>)
          .map((item) => HomeSectionModel.fromJson(item))
          .toList(),
    );
  }
}
