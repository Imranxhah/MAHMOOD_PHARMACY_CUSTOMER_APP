import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:customer_app/src/api/api_client.dart';
import 'package:customer_app/src/models/branch_model.dart';

class BranchProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<BranchModel> _branches = [];
  List<BranchModel> _foundBranches = [];
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isLocationLoading = false;
  String? _error;
  String? _locationError;

  List<BranchModel> get branches => _branches;
  List<BranchModel> get foundBranches => _foundBranches;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  bool get isLocationLoading => _isLocationLoading;
  String? get error => _error;
  String? get locationError => _locationError;

  Future<void> fetchLocationAndData({bool refresh = false}) async {
    // If we have location and data, and not refreshing, do nothing.
    if (!refresh && _currentPosition != null && _branches.isNotEmpty) {
      return;
    }

    _isLocationLoading = true;
    _locationError = null;
    notifyListeners();

    try {
      if (refresh || _currentPosition == null) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception("Location permissions are denied.");
          }
        }
        if (permission == LocationPermission.deniedForever) {
          throw Exception(
            "Location permissions are permanently denied, we cannot request permissions.",
          );
        }

        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }

      await listBranches(refresh: refresh);

      if (_currentPosition != null) {
        await findNearestBranch(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          refresh: refresh,
        );
      }
    } catch (e) {
      _locationError = e.toString();
    } finally {
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  Future<void> listBranches({bool refresh = false}) async {
    if (!refresh && _branches.isNotEmpty) return;

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
    bool refresh = false,
  }) async {
    if (!refresh && _foundBranches.isNotEmpty) return;

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
        _foundBranches = data
            .map((json) => BranchModel.fromJson(json))
            .toList();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _error = "No branches found near your location."; // Updated message
      } else if (e.response?.statusCode == 400) {
        _error = "Invalid location provided.";
      } else {
        _error =
            e.response?.data['message'] ??
            'Failed to find branches.'; // Updated message
      }
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
