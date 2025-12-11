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

  Future<void> uploadPrescription({required File image, String? notes}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.uploadPrescription(image: image, notes: notes);
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

  Future<void> listPrescriptions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.listPrescriptions();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _prescriptions = data.map((json) => PrescriptionModel.fromJson(json)).toList();
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
