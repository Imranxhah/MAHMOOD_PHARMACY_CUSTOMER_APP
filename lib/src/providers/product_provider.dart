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
    final bool currentStatus = _findCurrentStatus(productId);
    final bool optimisticStatus = !currentStatus;

    // 1. Optimistic Update
    _updateLocalFavoriteStatus(productId, optimisticStatus);
    notifyListeners();

    try {
      final response = await _apiClient.toggleFavorite(productId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final serverStatus = response.data['is_favorite'];
        // Ensure local state matches server state (should be same as optimistic)
        if (serverStatus != optimisticStatus) {
          _updateLocalFavoriteStatus(productId, serverStatus);
          notifyListeners();
        }
      }
    } on DioException catch (e) {
      // 2. Revert on failure
      _updateLocalFavoriteStatus(productId, currentStatus);
      notifyListeners();

      if (kDebugMode) {
        print('Error toggling favorite: ${e.message}');
      }
      rethrow;
    } catch (e) {
      // 2. Revert on failure
      _updateLocalFavoriteStatus(productId, currentStatus);
      notifyListeners();
      rethrow;
    }
  }

  bool _findCurrentStatus(int productId) {
    // Check products list
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) return _products[index].isFavorite;

    // Check home data
    if (_homeData != null) {
      for (var section in _homeData!.sections) {
        final p = section.products.where((p) => p.id == productId).firstOrNull;
        if (p != null) return p.isFavorite;
      }
    }

    // Check favorites
    final fav = _favorites.where((p) => p.id == productId).firstOrNull;
    if (fav != null) return fav.isFavorite;

    return false;
  }

  void _updateLocalFavoriteStatus(int productId, bool status) {
    // 1. Update in _products list
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index].isFavorite = status;
    }

    // 2. Update in _homeData
    if (_homeData != null) {
      for (var section in _homeData!.sections) {
        final sectionProductIndex = section.products.indexWhere(
          (p) => p.id == productId,
        );
        if (sectionProductIndex != -1) {
          section.products[sectionProductIndex].isFavorite = status;
        }
      }
    }

    // 3. Update in _favorites list
    final favIndex = _favorites.indexWhere((p) => p.id == productId);
    if (favIndex != -1) {
      if (!status) {
        _favorites.removeAt(favIndex);
      } else {
        _favorites[favIndex].isFavorite = status;
      }
    } else if (status) {
      // Try to find the product object to add to favorites
      ProductModel? product;
      if (index != -1) product = _products[index];
      if (product == null && _homeData != null) {
        for (var section in _homeData!.sections) {
          final p = section.products
              .where((p) => p.id == productId)
              .firstOrNull;
          if (p != null) {
            product = p;
            break;
          }
        }
      }
      if (product != null) {
        // Ensure the object we add has isFavorite = true
        // (It should be, because we reference the same object or updated it above)
        // If it's a copy, we might need to set it explicitly if not done.
        // Since we updated 'product' via reference in the lists above, it should be fine.
        _favorites.add(product);
      }
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
        _favorites = data
            .map((json) => ProductModel.fromJson(json['product']))
            .toList();
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
