import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:customer_app/src/api/api_client.dart';
import 'package:customer_app/src/models/branch_model.dart';

class BranchProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<BranchModel> _branches = [];
  List<BranchModel> _foundBranches = [];
  bool _isLoading = false;
  String? _error;

  List<BranchModel> get branches => _branches;
  List<BranchModel> get foundBranches => _foundBranches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> listBranches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.listBranches();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _branches = data.map((json) => BranchModel.fromJson(json)).toList();
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to load branches.';
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> findNearestBranch({
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _error = null;
    _foundBranches = []; // Clear previous search results
    notifyListeners();

    try {
      final response = await _apiClient.findNearestBranch(
        latitude: latitude,
        longitude: longitude,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data; // Expect a list now
        _foundBranches = data.map((json) => BranchModel.fromJson(json)).toList();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _error = "No branches found near your location."; // Updated message
      } else if (e.response?.statusCode == 400) {
        _error = "Invalid location provided.";
      } else {
        _error = e.response?.data['message'] ?? 'Failed to find branches.'; // Updated message
      }
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
