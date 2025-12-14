import 'package:flutter/foundation.dart';
import 'package:customer_app/src/api/api_client.dart';
import 'package:customer_app/src/models/banner_model.dart';
import 'package:dio/dio.dart';

class BannerProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<BannerModel> _banners = [];
  bool _isLoading = false;
  String? _error;

  List<BannerModel> get banners => _banners;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBanners({bool refresh = false}) async {
    // Basic caching: if not refreshing and banners are already loaded, return.
    // Use an additional flag like _areBannersLoaded if you need to distinguish
    // between empty list (no banners) and not yet loaded.
    if (!refresh && _banners.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.getBanners();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _banners = data.map((json) => BannerModel.fromJson(json)).toList();
      } else {
        // Handle API non-200 response
        _error = 'Failed to load banners: ${response.statusCode}';
        debugPrint('Failed to load banners: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to load banners due to network/API error';
      debugPrint('DioException fetching banners: ${e.message}');
    } catch (e) {
      _error = 'An unexpected error occurred while fetching banners: $e';
      debugPrint('Unexpected error fetching banners: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}