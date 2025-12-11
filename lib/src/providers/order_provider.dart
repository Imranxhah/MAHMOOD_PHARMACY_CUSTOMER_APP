import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:customer_app/src/api/api_client.dart';
import 'package:customer_app/src/models/order_model.dart';

class OrderProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<OrderModel> _orders = [];
  OrderModel? _selectedOrder;
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  OrderModel? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> placeOrder({
    required String shippingAddress,
    required String contactNumber,
    required List<Map<String, dynamic>> items,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.placeOrder(
        {
          "shipping_address": shippingAddress,
          "contact_number": contactNumber,
          "items": items,
        },
      );
      if (response.statusCode == 201) {
        _orders.insert(0, OrderModel.fromJson(response.data)); // Add new order to list
        _selectedOrder = OrderModel.fromJson(response.data);
        return Future.value();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && e.response?.data['error'] != null) {
        _error = e.response!.data['error'];
      } else {
        _error = e.response?.data['message'] ?? 'Failed to place order.';
      }
      rethrow;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> quickOrder({
    required int productId,
    required int quantity,
    String? shippingAddress, // Optional, API will use default if not provided
    String? contactNumber, // Optional
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.quickOrder(
        {
          "product_id": productId,
          "quantity": quantity,
          if (shippingAddress != null) "shipping_address": shippingAddress,
          if (contactNumber != null) "contact_number": contactNumber,
        },
      );
      if (response.statusCode == 201) {
        _orders.insert(0, OrderModel.fromJson(response.data)); // Add new order to list
        _selectedOrder = OrderModel.fromJson(response.data);
        return Future.value();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && e.response?.data['error'] != null) {
        _error = e.response!.data['error'];
      } else {
        _error = e.response?.data['message'] ?? 'Failed to place quick order.';
      }
      rethrow;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> listOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.listOrders();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _orders = data.map((json) => OrderModel.fromJson(json)).toList();
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to load orders.';
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getOrderDetail(int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.getOrderDetail(orderId);
      if (response.statusCode == 200) {
        _selectedOrder = OrderModel.fromJson(response.data);
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to load order details.';
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> validateCart(List<Map<String, dynamic>> cartItems) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.validateCart(cartItems);
      _isLoading = false;
      notifyListeners();
      return {'valid': response.data['valid'] ?? true, 'errors': response.data['errors'] ?? []};
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      // If server returns validation errors with status 400
      if (e.response?.statusCode == 400 && e.response?.data['errors'] != null) {
        return {'valid': false, 'errors': e.response!.data['errors']};
      }
      _error = e.response?.data['message'] ?? 'Failed to validate cart.';
      return {'valid': false, 'errors': [_error]};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      _error = 'An unexpected error occurred: $e';
      return {'valid': false, 'errors': [_error]};
    }
  }
}
