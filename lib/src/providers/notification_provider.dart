import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:customer_app/src/api/api_client.dart';
import 'package:customer_app/src/models/notification_model.dart';
import 'package:dio/dio.dart';
import 'package:awesome_notifications/awesome_notifications.dart' hide NotificationModel;
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

  // Local Notifications
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Init Local Notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      final DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotificationsPlugin.initialize(initializationSettings);

      // Create High Importance Channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Foreground Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null) {
          _localNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              ),
            ),
          );
        } else if (message.data.isNotEmpty) {
          String? title = message.data['title'];
          String? body = message.data['body'];
          
          if (title != null && body != null) {
            _localNotificationsPlugin.show(
              message.hashCode,
              title,
              body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  icon: '@mipmap/ic_launcher',
                ),
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

      // 4. Token Refresh Listener
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        registerDevice(newToken);
      });

      // 5. Subscribe to Topics
      await FirebaseMessaging.instance.subscribeToTopic("all_users");
    }
  }

  Future<void> registerDevice([String? token]) async {
    try {
      final fcmToken = token ?? await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final response = await _apiClient.registerDevice(fcmToken);
        if (kDebugMode) {
          print("Device Registration Status: ${response.statusCode}");
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
