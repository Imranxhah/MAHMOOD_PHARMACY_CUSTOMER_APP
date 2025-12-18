import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:customer_app/src/api/api_client.dart';
import 'package:customer_app/src/models/notification_model.dart';
import 'package:dio/dio.dart';
import 'package:awesome_notifications/awesome_notifications.dart' hide NotificationModel; // Hide colliding class

class NotificationProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
// ... (rest of the file content matches existing, just verifying context for the import change)

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

        // 1. Handle Notification Payload
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
        }
        // 2. Fallback: Handle Data-Only Payload (if notification is null)
        else if (message.data.isNotEmpty) {
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
        await _apiClient.registerDevice(fcmToken);
        if (kDebugMode) {
          print("Device Registered: $fcmToken");
        }
      }
    } catch (e) {
      // Fail silently as per requirement 4.1
      if (kDebugMode) {
        print("Failed to register device: $e");
      }
    }
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.getNotifications();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _notifications =
            data.map((json) => NotificationModel.fromJson(json)).toList();
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
    try {
      await _apiClient.markAllRead();
      fetchNotifications(); // Refetch to get updated status
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> markAsRead(int id) async {
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
      // Revert if failed (optional, or just fetchNotifications)
      fetchNotifications();
    }
  }

  Future<void> deleteNotification(int id) async {
    // Optimistic update
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();

    try {
      await _apiClient.deleteNotification(id);
    } catch (e) {
      // Revert or fetch on error
      fetchNotifications();
    }
  }
}
