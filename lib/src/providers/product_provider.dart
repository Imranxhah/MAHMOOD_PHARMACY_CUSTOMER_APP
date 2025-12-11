import 'package:flutter/foundation.dart';
import 'package:customer_app/src/api/api_client.dart';
import 'package:customer_app/src/models/category_model.dart';
import 'package:customer_app/src/models/home_data_model.dart';
import 'package:customer_app/src/models/product_model.dart';
import 'package:dio/dio.dart';

class ProductProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  List<ProductModel> _favorites = [];
  HomeDataModel? _homeData;
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  List<ProductModel> get products => _products;
  List<ProductModel> get favorites => _favorites;
  HomeDataModel? get homeData => _homeData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchHomeData({bool refresh = false}) async {
    if (_homeData != null && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.getHomeData();
      if (response.statusCode == 200) {
        _homeData = HomeDataModel.fromJson(response.data);
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to load home data';
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.getCategories();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _categories = data.map((json) => CategoryModel.fromJson(json)).toList();
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to load categories';
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProducts({
    String? search,
    int? categoryId,
    String? ordering,
    double? minPrice,
    double? maxPrice,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.getProducts(
        search: search,
        categoryId: categoryId,
        ordering: ordering,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _products = data.map((json) => ProductModel.fromJson(json)).toList();
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to load products';
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(int productId) async {
    try {
      final response = await _apiClient.toggleFavorite(productId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final newStatus = response.data['is_favorite'];

        // 1. Update in _products list
        final index = _products.indexWhere((p) => p.id == productId);
        if (index != -1) {
          _products[index].isFavorite = newStatus;
        }

        // 2. Update in _homeData
        if (_homeData != null) {
          for (var section in _homeData!.sections) {
            final sectionProductIndex = section.products.indexWhere((p) => p.id == productId);
            if (sectionProductIndex != -1) {
              section.products[sectionProductIndex].isFavorite = newStatus;
            }
          }
        }

        // 3. Update in _favorites list (remove if false, add if true - optional, or just re-fetch)
        // For simplicity and correctness, if we are just toggling visual state on other screens:
        final favIndex = _favorites.indexWhere((p) => p.id == productId);
        if (favIndex != -1) {
           _favorites[favIndex].isFavorite = newStatus;
           // If it was unfavorited, we might want to remove it from the local favorites list immediately
           if (!newStatus) {
             _favorites.removeAt(favIndex);
           }
        }

        notifyListeners();
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error toggling favorite: ${e.message}');
      }
      rethrow;
    }
  }

  Future<void> fetchFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.getFavorites();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        // The endpoint returns a list of favorite objects containing nested product info
        // Structure: [{"id": 5, "product": { ... }, ... }]
        _favorites = data.map((json) => ProductModel.fromJson(json['product'])).toList();
      }
    } on DioException catch (e) {
       if (kDebugMode) {
        print('Error fetching favorites: ${e.message}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
