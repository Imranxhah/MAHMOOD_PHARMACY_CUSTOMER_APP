import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:awesome_notifications/awesome_notifications.dart'; // Import awesome_notifications
import 'src/constants/app_theme.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/product_provider.dart';
import 'src/providers/order_provider.dart';
import 'src/providers/cart_provider.dart';
import 'src/providers/prescription_provider.dart';
import 'src/providers/branch_provider.dart';
import 'src/providers/address_provider.dart';
import 'src/providers/theme_provider.dart';
import 'src/providers/banner_provider.dart';
import 'src/providers/notification_provider.dart'; // Import NotificationProvider
import 'src/features/splash/presentation/splash_screen.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // ignore: avoid_print
  print("Handling a background message: ${message.messageId}");


  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // If the message is data-only (no notification payload), try to show it.
  if (message.notification == null && message.data.isNotEmpty) {
    String? title = message.data['title'];
    String? body = message.data['body'];

    if (title != null && body != null) {
      await flutterLocalNotificationsPlugin.show(
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

  // Update badge count for background messages
  if (message.data.containsKey('badge')) {
    int badgeCount = int.tryParse(message.data['badge']!) ?? 0;
    AwesomeNotifications().setGlobalBadgeCounter(badgeCount);
  }
}

// Global navigator key for navigation outside of widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Function to handle navigation based on notification data
void handleNotificationNavigation(RemoteMessage message) {
  if (message.data.containsKey('type')) {
    final type = message.data['type'];
    final orderId = message.data['order_id']; // Assuming order_id is always a String
    
    // Perform navigation based on the type and orderId
    if (type == 'order_update' && orderId != null) {
      // Navigate to the OrderDetailsScreen.
      // This requires the screen to be defined and potentially accept arguments.
      // For now, we'll just print, and proper navigation should be implemented
      // within the app's routing system (e.g., go_router, named routes).
      print("Navigating to order details for order ID: $orderId");
      // Example: navigatorKey.currentState?.pushNamed('/order_details', arguments: orderId);
    }
    // Add more cases for other notification types as needed
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle message received when the app is in the background or terminated
  // and the user taps on it.
  FirebaseMessaging.onMessageOpenedApp.listen(handleNotificationNavigation);

  // Handle message received when the app is terminated and launched by tapping the notification.
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    handleNotificationNavigation(initialMessage);
  }

  runApp(const MahmoodPharmacyApp());
}

class MahmoodPharmacyApp extends StatelessWidget {
  const MahmoodPharmacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..init()), // Init NotificationProvider
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey, // Set the navigator key
            title: 'Mahmood Pharmacy',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
