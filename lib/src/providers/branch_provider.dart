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
  // Add variable to track the position used for the last successful search
  Position? _lastSearchPosition;
  
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
    debugPrint("fetchLocationAndData called. Refresh: $refresh");
    // If we have location and data, and not refreshing, do nothing.
    if (!refresh && _currentPosition != null && _branches.isNotEmpty) {
      debugPrint("Data already available and not refreshing. Skipping.");
      return;
    }

    _isLocationLoading = true;
    _locationError = null;
    notifyListeners();

    try {
      if (refresh || _currentPosition == null) {
        debugPrint("Checking location permissions...");
        LocationPermission permission = await Geolocator.checkPermission();
        debugPrint("Current permission status: $permission");
        
        if (permission == LocationPermission.denied) {
          debugPrint("Permission denied. Requesting permission...");
          permission = await Geolocator.requestPermission();
          debugPrint("Permission request result: $permission");
          if (permission == LocationPermission.denied) {
            throw Exception("Location permissions are denied.");
          }
        }
        if (permission == LocationPermission.deniedForever) {
          debugPrint("Permission denied forever.");
          throw Exception(
            "Location permissions are permanently denied, we cannot request permissions.",
          );
        }

        debugPrint("Getting current position...");
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        debugPrint("Position acquired: $_currentPosition");
      }

      debugPrint("Listing branches...");
      await listBranches(refresh: refresh);
      debugPrint("Branches loaded: ${_branches.length}");

      if (_currentPosition != null) {
        debugPrint("Finding nearest branch...");
        await findNearestBranch(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          refresh: refresh,
        );
      } else {
        debugPrint("Location unavailable (position null), using all branches fallback.");
        // Fallback: Use all branches if location is not available
        _foundBranches = List.from(_branches);
        _lastSearchPosition = null; // Mark that we haven't searched with a valid position
      }
    } on LocationServiceDisabledException catch (e) {
      debugPrint("LocationServiceDisabledException caught: $e");
      debugPrint("Falling back to all branches due to disabled location service.");
      // Fallback: User disabled location, show all branches
      _locationError = null; // Clear error so UI doesn't show "Location disabled"
      await listBranches(refresh: refresh); // Ensure branches are loaded
      _foundBranches = List.from(_branches);
      _lastSearchPosition = null; // Mark that we haven't searched with a valid position
    } catch (e) {
      debugPrint("Error in fetchLocationAndData: $e");
      debugPrint("Falling back to all branches due to error.");
      _locationError = null; // Clear error to show dropdown
      await listBranches(refresh: refresh); // Ensure branches are loaded
      _foundBranches = List.from(_branches);
      _lastSearchPosition = null; // Mark that we haven't searched with a valid position
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
    // Check if we already have data for this location (or close enough)
    bool sameLocation = false;
    if (_lastSearchPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastSearchPosition!.latitude, 
        _lastSearchPosition!.longitude, 
        latitude, 
        longitude
      );
      // Consider same location if moved less than 100 meters
      if (distance < 100) {
        sameLocation = true;
      }
    }

    if (!refresh && _foundBranches.isNotEmpty && sameLocation) {
       debugPrint("Returning cached branches (location match).");
       return;
    }

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
        
        // Update the last search position on success
        _lastSearchPosition = Position(
          longitude: longitude,
          latitude: latitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0, 
          headingAccuracy: 0,
        );
      }
    } on DioException catch (e) {
      // Fallback to all branches on error
      _foundBranches = List.from(_branches);
      _lastSearchPosition = null; // Reset on error as we are falling back
      
      if (e.response?.statusCode == 404) {
        _error = "No branches found near your location. Showing all branches.";
      } else if (e.response?.statusCode == 400) {
        _error = "Invalid location. Showing all branches.";
      } else {
        _error = e.response?.data['message'] ?? 'Failed to find nearest branches. Showing all branches.';
      }
    } catch (e) {
      _foundBranches = List.from(_branches);
      _lastSearchPosition = null;
      _error = 'An unexpected error occurred. Showing all branches.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
