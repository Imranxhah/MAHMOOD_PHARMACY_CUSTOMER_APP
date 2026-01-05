import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:customer_app/src/api/api_client.dart';
import 'package:customer_app/src/models/order_model.dart';

class OrderProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Order> _orders = [];
  Order? _selectedOrder;
  bool _isLoading = false;
  bool _isOrdersLoaded = false;
  String? _error;

  List<Order> get orders => _orders;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> placeOrder({
    required String shippingAddress,
    required String contactNumber,
    required List<Map<String, dynamic>> items,
    int? branchId,
    String? paymentMethod,
    String orderType = "Normal",
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.placeOrder({
        "shipping_address": shippingAddress,
        "contact_number": contactNumber,
        "items": items,
        if (branchId != null) "branch_id": branchId,
        if (paymentMethod != null) "payment_method": paymentMethod,
        "order_type": orderType,
      });
      if (response.statusCode == 201) {
        _orders.insert(
          0,
          Order.fromJson(response.data),
        ); // Add new order to list
        _selectedOrder = Order.fromJson(response.data);
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



  Future<void> listOrders({bool forceRefresh = false}) async {
    if (_isOrdersLoaded && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.listOrders();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _orders = data.map((json) => Order.fromJson(json)).toList();
        _isOrdersLoaded = true;
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
    // Check if order exists locally first
    try {
      final localOrder = _orders.firstWhere((o) => o.id == orderId);
      _selectedOrder = localOrder;
      notifyListeners();
      // Optionally fetch fresh data in background if needed, but for now we rely on cache
      return; 
    } catch (_) {
      // Order not found locally, proceed to fetch
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.getOrderDetail(orderId);
      if (response.statusCode == 200) {
        _selectedOrder = Order.fromJson(response.data);
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

  Future<void> cancelOrder(int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.cancelOrder(orderId);
      if (response.statusCode == 200) {
        // Update local status instead of refetching
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          final updatedOrder = _orders[index].copyWith(status: 'Cancelled');
          _orders[index] = updatedOrder;
          
          if (_selectedOrder != null && _selectedOrder!.id == orderId) {
            _selectedOrder = updatedOrder;
          }
        }
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to cancel order.';
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteOrder(int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.deleteOrder(orderId);
      if (response.statusCode == 204) { // 204 No Content is typical for successful DELETE
        _orders.removeWhere((order) => order.id == orderId);
      }
    } on DioException catch (e) {
      if (e.response?.data is Map && (e.response?.data as Map).containsKey('message')) {
        _error = e.response?.data['message'];
      } else {
         // Fallback for non-JSON errors (like 500 HTML) or missing 'message' key
        _error = 'Failed to delete order. Server returned status ${e.response?.statusCode}';
      }
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> validateCart(
    List<Map<String, dynamic>> cartItems,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.validateCart(cartItems);
      _isLoading = false;
      notifyListeners();
      return {
        'valid': response.data['valid'] ?? true,
        'errors': response.data['errors'] ?? [],
      };
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      // If server returns validation errors with status 400
      if (e.response?.statusCode == 400 && e.response?.data['errors'] != null) {
        return {'valid': false, 'errors': e.response!.data['errors']};
      }
      _error = e.response?.data['message'] ?? 'Failed to validate cart.';
      return {
        'valid': false,
        'errors': [_error],
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      _error = 'An unexpected error occurred: $e';
      return {
        'valid': false,
        'errors': [_error],
      };
    }
  }
}
