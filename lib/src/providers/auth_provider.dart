import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/src/api/api_client.dart';
import 'package:customer_app/src/services/secure_storage_service.dart';
import 'package:customer_app/src/models/user_model.dart';
import 'package:jwt_decode/jwt_decode.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  authenticating,
  registering,
}

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storageService = SecureStorageService();

  AuthStatus _authStatus = AuthStatus.uninitialized;
  User? _user;
  bool _isAdmin = false;

  AuthStatus get authStatus => _authStatus;
  User? get user => _user;
  bool get isAdmin => _isAdmin;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final accessToken = await _storageService.read('access');
    if (accessToken != null) {
      try {
        await _loadUser(accessToken);
        // If _loadUser succeeds (even after refresh), we are authenticated
        _authStatus = AuthStatus.authenticated;
      } catch (e) {
        _authStatus = AuthStatus.unauthenticated;
      }
    } else {
      _authStatus = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<String> login(String email, String password) async {
    _authStatus = AuthStatus.authenticating;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        'auth/login/',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['access'];
        final refreshToken = response.data['refresh'];

        await Future.wait([
          _storageService.write('access', accessToken),
          _storageService.write('refresh', refreshToken),
        ]);

        _loadUser(accessToken); // Fire and forget
        _authStatus = AuthStatus.authenticated;
        notifyListeners();
        return 'success';
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final responseData = e.response?.data;
        if (responseData != null && responseData['code'] != null) {
          final code = responseData['code']?.toString().trim().toLowerCase();

          if (code == 'unverified_user') {
            _authStatus = AuthStatus.unauthenticated;
            notifyListeners();
            return 'unverified';
          } else if (code == 'authentication_failed') {
            _authStatus = AuthStatus.unauthenticated;
            notifyListeners();
            return 'authentication_failed';
          }
        }
        // If 401 but no specific code or unknown code, treat as authentication_failed
        _authStatus = AuthStatus.unauthenticated;
        notifyListeners();
        return 'authentication_failed';
      } else if (e.response?.statusCode == 400) {
        // Handle 400 Bad Request, usually validation errors.
        // The frontend currently only expects 'unverified', 'authentication_failed', or 'success'.
        // For 400, it's a 'failed' case from the perspective of this login function's return strings.
        _authStatus = AuthStatus.unauthenticated;
        notifyListeners();
        return 'failed';
      }
      // For any other DioException (e.g., 500, network error)
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
      return 'failed';
    }
    // Any other non-DioException errors (e.g., programming errors)
    _authStatus = AuthStatus.unauthenticated;
    notifyListeners();
    return 'failed';
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String firstName,
    String lastName,
    String mobile,
  ) async {
    _authStatus = AuthStatus.registering;

    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        'auth/register/',

        data: {
          'email': email,

          'password': password,

          'first_name': firstName,

          'last_name': lastName,

          'mobile': mobile,
        },
      );

      if (response.statusCode == 201) {
        _authStatus = AuthStatus.unauthenticated;

        notifyListeners();

        return {'success': true, 'data': response.data};
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409 &&
          e.response?.data['status'] == 'unverified') {
        _authStatus = AuthStatus.unauthenticated;

        notifyListeners();

        return {
          'success': false,
          'status': 'unverified',
          'data': e.response!.data,
        };
      }

      if (e.response?.statusCode == 400) {
        // Handle validation errors explicitly

        return {
          'success': false,
          'status': 'validation_error',
          'data': e.response!.data,
        };
      }

      if (e.response != null) {
        return {'success': false, 'data': e.response!.data};
      }

      // If it's a DioException but not a specific 409 or 400

      return {
        'success': false,
        'data': 'An unknown error occurred (DioException)',
      };
    }

    // Any other non-DioException errors

    return {'success': false, 'data': 'An unknown error occurred'};
  }

  Future<Map<String, dynamic>> resendOtp(String email) async {
    try {
      final response = await _apiClient.dio.post(
        'auth/resend-otp/',
        data: {'email': email},
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'OTP sent successfully.',
        };
      }
      return {'success': false, 'message': 'Failed to send OTP.'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 &&
          e.response?.data['message'] != null) {
        return {'success': false, 'message': e.response!.data['message']};
      }
      if (e.response?.statusCode == 404 && e.response?.data['error'] != null) {
        return {'success': false, 'message': e.response!.data['error']};
      }
      return {
        'success': false,
        'message': 'Failed to resend OTP. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await _apiClient.dio.post(
        'auth/verify/',
        data: {'email': email, 'otp_code': otp},
      );
      if (response.statusCode == 200) {
        if (response.data != null &&
            response.data['access'] != null &&
            response.data['refresh'] != null) {
          final accessToken = response.data['access'];
          final refreshToken = response.data['refresh'];

          await Future.wait([
            _storageService.write('access', accessToken),
            _storageService.write('refresh', refreshToken),
          ]);

          _loadUser(accessToken); // Fire and forget
          _authStatus = AuthStatus.authenticated;
          notifyListeners();
          return {
            'success': true,
            'message':
                response.data['message'] ?? 'Account verified successfully.',
          };
        } else {
          _authStatus = AuthStatus.unauthenticated;
          notifyListeners();
          return {
            'success': true,
            'message':
                response.data['message'] ?? 'Account verified successfully.',
          };
        }
      }
      return {'success': false, 'message': 'Verification failed.'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 &&
          e.response?.data['non_field_errors'] != null) {
        return {
          'success': false,
          'message': e.response!.data['non_field_errors'][0],
        };
      }
      return {
        'success': false,
        'message': 'OTP verification failed. Please try again.',
      };
    }
  }

  Future<void> logout() async {
    await _storageService.deleteAll();
    _user = null;
    _isAdmin = false;
    _authStatus = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _loadUser(String token) async {
    Map<String, dynamic> payload = Jwt.parseJwt(token);
    _isAdmin = payload['is_staff'] ?? false;
    // After login, we can fetch user profile
    try {
      final response = await _apiClient.dio.get('users/profile/');
      if (response.statusCode == 200) {
        _user = User.fromJson(response.data);
        notifyListeners();
      }
    } catch (e) {
      // Handle error, maybe logout user
    }
  }

  // Password Reset Methods
  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await _apiClient.dio.post(
        'auth/password/reset/',
        data: {'email': email},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> confirmPasswordReset(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        'auth/password/reset/confirm/',
        data: {'email': email, 'otp_code': otp, 'new_password': newPassword},
      );
      if (response.statusCode == 200) {
        // Password reset successful, now attempt to log in
        try {
          final loginResponse = await _apiClient.dio.post(
            'auth/login/',
            data: {'email': email, 'password': newPassword},
          );

          if (loginResponse.statusCode == 200) {
            final accessToken = loginResponse.data['access'];
            final refreshToken = loginResponse.data['refresh'];

            await Future.wait([
              _storageService.write('access', accessToken),
              _storageService.write('refresh', refreshToken),
            ]);

            _loadUser(accessToken); // Fire and forget
            _authStatus = AuthStatus.authenticated;
            notifyListeners();
            return true; // Password reset and auto-login successful
          } else {
            _authStatus = AuthStatus.unauthenticated;
            notifyListeners();
            return false; // Password reset successful, but auto-login failed
          }
        } on DioException catch (loginError) {
          debugPrint(
            'Auto-login after password reset failed: ${loginError.response?.data}',
          );
          _authStatus = AuthStatus.unauthenticated;
          notifyListeners();
          return false; // Password reset successful, but auto-login failed due to error
        }
      }
      return false; // Password reset failed
    } catch (e) {
      debugPrint('Password reset confirmation failed: $e');
      return false;
    }
  }

  // Profile Methods
  Future<bool> updateProfile(Map<String, String> data) async {
    try {
      final response = await _apiClient.dio.patch('users/profile/', data: data);
      if (response.statusCode == 200) {
        _user = User.fromJson(response.data);
        notifyListeners();
        return true;
      }
    } catch (e) {
      // handle error
    }
    return false;
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _apiClient.changePassword({
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      return Future.value();
    } on DioException catch (e) {
      // Re-throw DioException to allow calling widget to handle specific error messages
      rethrow;
    } catch (e) {
      // Re-throw other exceptions as a generic exception
      throw Exception(
        'An unexpected error occurred during password change: $e',
      );
    }
  }

  // Admin Methods
  Future<List<User>> getAllUsers() async {
    if (!_isAdmin) return [];
    try {
      final response = await _apiClient.dio.get('users/');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((userJson) => User.fromJson(userJson))
            .toList();
      }
    } catch (e) {
      // handle error
    }
    return [];
  }
}
