import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:customer_app/src/api/api_client.dart';
import 'package:customer_app/src/models/prescription_model.dart';

class PrescriptionProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<PrescriptionModel> _prescriptions = [];
  bool _isLoading = false;
  String? _error;

  List<PrescriptionModel> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> uploadPrescription({
    required File image,
    required String contactNumber,
    required int branchId,
    required String address,
    String? note,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.uploadPrescription(
        image: image,
        contactNumber: contactNumber,
        branchId: branchId,
        address: address,
        note: note,
      );
      if (response.statusCode == 201) {
        _prescriptions.insert(0, PrescriptionModel.fromJson(response.data));
        return Future.value();
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to upload prescription.';
      rethrow;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePrescription(
    int id, {
    String? address,
    String? contactNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.updatePrescription(
        id,
        address: address,
        contactNumber: contactNumber,
      );
      if (response.statusCode == 200) {
        final index = _prescriptions.indexWhere((p) => p.id == id);
        if (index != -1) {
          _prescriptions[index] = PrescriptionModel.fromJson(response.data);
        }
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to update prescription.';
      rethrow;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> listPrescriptions({bool refresh = false}) async {
    if (!refresh && _prescriptions.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.listPrescriptions();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _prescriptions = data
            .map((json) => PrescriptionModel.fromJson(json))
            .toList();
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to load prescriptions.';
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePrescription(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.deletePrescription(id);
      if (response.statusCode == 204) {
        _prescriptions.removeWhere((p) => p.id == id);
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to delete prescription.';
      rethrow;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
