import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart' hide NotificationModel;
import 'package:customer_app/src/api/api_client.dart';
import 'package:customer_app/src/models/notification_model.dart';
import 'package:dio/dio.dart';
import 'package:customer_app/src/services/secure_storage_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storageService = SecureStorageService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Request AwesomeNotifications permission
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Foreground Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;

        if (notification != null) {
          AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: notification.hashCode.abs(),
              channelKey: 'high_importance_channel',
              title: notification.title,
              body: notification.body,
              notificationLayout: NotificationLayout.Default,
              icon: null,
            ),
          );
        } else if (message.data.isNotEmpty) {
          String? title = message.data['title'];
          String? body = message.data['body'];
          
          if (title != null && body != null) {
            AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: message.hashCode.abs(),
                channelKey: 'high_importance_channel',
                title: title,
                body: body,
                notificationLayout: NotificationLayout.Default,
                icon: null,
              ),
            );
          }
        }
        
        // Refresh notifications list if user is on that screen
        fetchNotifications();

        // Update badge count
        if (message.data.containsKey('badge')) {
          int badgeCount = int.tryParse(message.data['badge']!) ?? 0;
          AwesomeNotifications().setGlobalBadgeCounter(badgeCount);
        }
      });

      // 3. Token Refresh Listener
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        registerDevice(newToken);
      });

      // 4. Subscribe to Topics
      await FirebaseMessaging.instance.subscribeToTopic("all_users");
    }
  }

  Future<void> registerDevice([String? token, bool force = false]) async {
    try {
      final fcmToken = token ?? await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        // Check if we already registered this token
        if (!force) {
          final savedToken = await _storageService.read('device_fcm_token');
          if (savedToken == fcmToken) {
            return;
          }
        }

        final response = await _apiClient.registerDevice(fcmToken);
        
        // Save the token locally after successful registration
        if (response.statusCode == 200 || response.statusCode == 201) {
          await _storageService.write('device_fcm_token', fcmToken);
        }

        if (kDebugMode) {
          print("Device Registered with Token: $fcmToken");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to register device: $e");
      }
    }
  }

  Future<bool> _isAuthenticated() async {
    final token = await _storageService.read('access');
    return token != null;
  }

  Future<void> fetchNotifications() async {
    // If not authenticated, we can't fetch notifications from this API
    if (!await _isAuthenticated()) {
      _notifications = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.getNotifications();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        // Filter out broadcast notifications (negative IDs)
        _notifications = data
            .map((json) => NotificationModel.fromJson(json))
            .where((n) => n.id >= 0)
            .toList();
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Failed to load notifications';
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    if (!await _isAuthenticated()) return;

    // Optimistic Update: Mark all as read locally first
    _notifications = _notifications.map((n) {
      return NotificationModel(
        id: n.id,
        title: n.title,
        body: n.body,
        isRead: true,
        createdAt: n.createdAt,
      );
    }).toList();
    notifyListeners();

    try {
      await _apiClient.markAllRead();
      // Optionally fetch again to ensure sync
      // await fetchNotifications(); 
    } catch (e) {
      // If error, maybe revert or just silently fail? 
      // For now, we'll try to re-fetch to restore correct state
      fetchNotifications();
    }
  }

  Future<void> markAsRead(int id) async {
    if (!await _isAuthenticated()) return;

    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        title: _notifications[index].title,
        body: _notifications[index].body,
        isRead: true,
        createdAt: _notifications[index].createdAt,
      );
      notifyListeners();
    }

    try {
      await _apiClient.updateNotification(id, isRead: true);
    } catch (e) {
      // Revert or re-fetch on error
      fetchNotifications();
    }
  }

  Future<void> deleteNotification(int id) async {
    if (!await _isAuthenticated()) return;

    // Optimistic update
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();

    try {
      await _apiClient.deleteNotification(id);
    } catch (e) {
      // Revert or re-fetch on error
      fetchNotifications();
    }
  }
}
