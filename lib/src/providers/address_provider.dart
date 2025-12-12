import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:customer_app/src/api/api_client.dart';
import 'package:customer_app/src/models/address_model.dart';

class AddressProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String? _error;

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.getAddresses();
      if (response.statusCode == 200) {
        _addresses = (response.data as List)
            .map((json) => AddressModel.fromJson(json))
            .toList();
      } else {
        _error = "Failed to load addresses";
      }
    } on DioException catch (e) {
      _error = e.response?.data['detail'] ?? "An error occurred";
    } catch (e) {
      _error = "An unexpected error occurred";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAddress(String address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.createAddress({'address': address});
      if (response.statusCode == 201) {
        final newAddress = AddressModel.fromJson(response.data);
        _addresses.add(newAddress);
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _error = e.response?.data.toString() ?? "Failed to create address";
    } catch (e) {
      _error = "An unexpected error occurred";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> updateAddress(int id, String address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.updateAddress(id, {'address': address});
      if (response.statusCode == 200) {
        final updatedAddress = AddressModel.fromJson(response.data);
        final index = _addresses.indexWhere((a) => a.id == id);
        if (index != -1) {
          _addresses[index] = updatedAddress;
          notifyListeners();
        }
        return true;
      }
    } on DioException catch (e) {
      _error = e.response?.data.toString() ?? "Failed to update address";
    } catch (e) {
      _error = "An unexpected error occurred";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> deleteAddress(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.deleteAddress(id);
      if (response.statusCode == 204) {
        _addresses.removeWhere((a) => a.id == id);
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      // 404 is also considered "success" in terms of "address is gone" for the list
      if (e.response?.statusCode == 404) {
        _addresses.removeWhere((a) => a.id == id);
        notifyListeners();
        return true;
      }
      _error = e.response?.data['detail'] ?? "Failed to delete address";
    } catch (e) {
      _error = "An unexpected error occurred";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}
