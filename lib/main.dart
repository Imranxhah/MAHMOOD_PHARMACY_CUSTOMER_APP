import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:customer_app/src/utils/notification_utils.dart';
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
import 'src/providers/notification_provider.dart';
import 'src/features/splash/presentation/splash_screen.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  try {
    await NotificationUtils.initializeNotifications();
    
    // If the message is data-only (no notification payload), try to show it.
    if (message.notification == null && message.data.isNotEmpty) {
      String? title = message.data['title'];
      String? body = message.data['body'];

      if (title != null && body != null) {
        await AwesomeNotifications().createNotification(
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

    // Update badge count for background messages
    if (message.data.containsKey('badge')) {
      int badgeCount = int.tryParse(message.data['badge']!) ?? 0;
      AwesomeNotifications().setGlobalBadgeCounter(badgeCount);
    }
  } catch (e, stack) {
    if (kDebugMode) {
      print("Error in background handler: $e");
      print(stack);
    }
  }
}

// Global navigator key for navigation outside of widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Function to handle navigation based on notification data
void handleNotificationNavigation(RemoteMessage message) {
  // Navigation Guard: Ensure navigator is mounted
  if (navigatorKey.currentState == null) {
    // Determine if we need to store this as a pending action in a provider
    // For now, we return to avoid crashing.
    if (kDebugMode) {
      print("Navigator not ready. Skipping direct navigation.");
    }
    return;
  }

  if (message.data.containsKey('type')) {
    final type = message.data['type'];
    final orderId = message.data['order_id']; // Assuming order_id is always a String
    
    // Perform navigation based on the type and orderId
    if (type == 'order_update' && orderId != null) {
      print("Navigating to order details for order ID: $orderId");
      // Example: navigatorKey.currentState?.pushNamed('/order_details', arguments: orderId);
    }
    // Add more cases for other notification types as needed
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize AwesomeNotifications
  await NotificationUtils.initializeNotifications();

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