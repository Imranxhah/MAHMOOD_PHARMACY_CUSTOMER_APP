import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:customer_app/src/constants/api_constants.dart';
import 'package:customer_app/src/services/secure_storage_service.dart';

class ApiClient {
  final Dio _dio;
  final SecureStorageService _storageService;
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal()
      : _dio = Dio(),
        _storageService = SecureStorageService() {
    _dio.options.baseUrl = _getBaseUrl();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await _storageService.read('access');
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final code = e.response?.data['code']?.toString().trim().toLowerCase();
            // If the 401 is due to specific authentication issues, let it propagate
            if (code == 'unverified_user' || code == 'authentication_failed') {
              return handler.next(e);
            }

            // Otherwise, assume token expired and try to refresh
            try {
              final newAccessToken = await _refreshToken();
              if (newAccessToken != null) {
                // Update the failed request's header
                e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                // Retry the failed request
                final response = await _dio.fetch(e.requestOptions);
                return handler.resolve(response);
              } else {
                 // If refresh fails, logout user
                await _logout();
                return handler.next(e);
              }
            } catch (refreshError) {
              await _logout();
              return handler.next(e);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  static String _getBaseUrl() {
    if (kIsWeb) {
      return ApiConstants.webBaseUrl;
    } else if (Platform.isAndroid) {
      return ApiConstants.androidBaseUrl;
    } else if (Platform.isIOS) {
      return ApiConstants.iosBaseUrl;
    }
    // Default fallback
    return ApiConstants.webBaseUrl;
  }

  Future<String?> _refreshToken() async {
    final refreshToken = await _storageService.read('refresh');
    if (refreshToken == null) {
      return null;
    }

    try {
      final response = await Dio().post(
        '${_getBaseUrl()}auth/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];
        await _storageService.write('access', newAccessToken);
        return newAccessToken;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> _logout() async {
    await _storageService.deleteAll();
    // Here you should navigate the user to the login screen.
    // This part is tricky to do from the API client.
    // A better approach is to use a state management solution to listen to auth state changes.
  }

  // --- Products Module ---

  Future<Response> getCategories() async {
    return await _dio.get('categories/');
  }

  Future<Response> getHomeData() async {
    return await _dio.get('products/home/');
  }

  Future<Response> getProducts({
    String? search,
    int? categoryId,
    String? ordering,
    double? minPrice,
    double? maxPrice,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (categoryId != null) queryParams['category'] = categoryId;
    if (ordering != null && ordering.isNotEmpty) queryParams['ordering'] = ordering;
    if (minPrice != null) queryParams['min_price'] = minPrice;
    if (maxPrice != null) queryParams['max_price'] = maxPrice;

    return await _dio.get('products/', queryParameters: queryParams);
  }

  // --- Favorites Module ---

  Future<Response> toggleFavorite(int productId) async {
    return await _dio.post('favorites/toggle/', data: {'product_id': productId});
  }

  Future<Response> getFavorites() async {
    return await _dio.get('favorites/');
  }

  // --- Order Management Module ---

  Future<Response> placeOrder(Map<String, dynamic> orderData) async {
    return await _dio.post('orders/', data: orderData);
  }

  Future<Response> listOrders() async {
    return await _dio.get('orders/');
  }

  Future<Response> getOrderDetail(int orderId) async {
    return await _dio.get('orders/$orderId/');
  }

  Future<Response> quickOrder(Map<String, dynamic> orderData) async {
    return await _dio.post('orders/quick-order/', data: orderData);
  }

  Future<Response> validateCart(List<Map<String, dynamic>> cartItems) async {
    return await _dio.post('cart/validate/', data: {'items': cartItems});
  }

  // --- Prescriptions Module ---

  Future<Response> uploadPrescription({
    required File image,
    String? notes,
  }) async {
    String fileName = image.path.split('/').last;
    FormData formData = FormData.fromMap({
      "image": await MultipartFile.fromFile(image.path, filename: fileName),
      if (notes != null) "notes": notes,
    });
    return await _dio.post(
      'prescriptions/upload/',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }

  Future<Response> listPrescriptions() async {
    return await _dio.get('prescriptions/');
  }

  Future<Response> deletePrescription(int id) async {
    return await _dio.delete('prescriptions/$id/');
  }

  // --- Branches Module ---

  Future<Response> listBranches() async {
    return await _dio.get('branches/');
  }

  Future<Response> findNearestBranch({
    required double latitude,
    required double longitude,
  }) async {
    return await _dio.get('branches/nearest/', queryParameters: {
      'lat': latitude,
      'long': longitude,
    });
  }

  // --- Address Management Module ---

  Future<Response> getAddresses() async {
    return await _dio.get('addresses/');
  }

  Future<Response> createAddress(Map<String, dynamic> addressData) async {
    return await _dio.post('addresses/', data: addressData);
  }

  Future<Response> updateAddress(int id, Map<String, dynamic> addressData) async {
    return await _dio.put('addresses/$id/', data: addressData);
  }

  Future<Response> deleteAddress(int id) async {
    return await _dio.delete('addresses/$id/');
  }

  // --- Auth Module (Password) ---
  Future<Response> changePassword(Map<String, dynamic> passwordData) async {
    return await _dio.post('auth/password/change/', data: passwordData);
  }
}
