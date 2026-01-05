import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add shared_preferences import
import 'package:customer_app/src/features/home/presentation/main_screen.dart';
import 'package:customer_app/src/features/auth/presentation/screens/welcome_screen.dart';
import 'package:customer_app/src/providers/product_provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/providers/notification_provider.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:customer_app/main.dart';
import 'package:customer_app/src/common_widgets/pharmacy_loader.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:customer_app/src/api/api_client.dart';
import 'package:customer_app/src/features/splash/presentation/force_update_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String? _error;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  // Hippie Blue theme colors
  static const Color primaryColor = Color(0xFF4C9BEB); // Hippie Blue primary
  static const Color backgroundColor = Color(0xFFF8FCFF);
  static const Color darkTextColor = Color(0xFF0D3B66);
  static const Color lightTextColor = Color(0xFF5A7C99);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAppInitialization();
    AwesomeNotifications().resetGlobalBadge();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  Future<void> _startAppInitialization() async {
    // Check for app update first
    final updateRequired = await _checkAppVersion();
    if (updateRequired) return;

    if (!mounted) return;

    // Force initialization of NotificationProvider to request permissions early
    Provider.of<NotificationProvider>(context, listen: false);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.authStatus != AuthStatus.uninitialized) {
      await _checkAuthAndProceed();
    } else {
      authProvider.addListener(_authListener);
    }
  }

  Future<bool> _checkAppVersion() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.getAppVersion();
      
      if (response.statusCode == 200) {
        final data = response.data;
        bool forceUpdate = data['force_update'] ?? false;

        if (!forceUpdate) {
          return false;
        }

        String serverVersion = data['version'] ?? '1.0.0';
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String localVersion = packageInfo.version;

        if (_isServerVersionNewer(serverVersion, localVersion)) {
          if (!mounted) return false;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ForceUpdateScreen(
                message: data['message'] ?? 'A new version is available.',
                storeUrl: data['store_url'],
              ),
            ),
          );
          return true;
        }
      }
    } catch (e) {
      debugPrint("Error checking app version: $e");
      // Continue app flow on error
    }
    return false;
  }

  bool _isServerVersionNewer(String serverVersion, String localVersion) {
    List<String> serverParts = serverVersion.split('.');
    List<String> localParts = localVersion.split('.');

    for (int i = 0; i < serverParts.length && i < localParts.length; i++) {
      int serverPart = int.tryParse(serverParts[i]) ?? 0;
      int localPart = int.tryParse(localParts[i]) ?? 0;

      if (serverPart > localPart) {
        return true;
      } else if (serverPart < localPart) {
        return false;
      }
    }
    // If versions are same length and parts are equal, or if one version is longer but with 0s, 
    // we can consider them equal or handle length mismatch. 
    // Assuming semantic versioning (x.y.z), usually length is 3. 
    // If server version has more parts (e.g. 1.0.0.1 vs 1.0.0), it's newer.
    if (serverParts.length > localParts.length) return true;

    return false;
  }

  void _authListener() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authStatus != AuthStatus.uninitialized) {
      authProvider.removeListener(_authListener);
      _checkAuthAndProceed();
    }
  }

  Future<void> _checkAuthAndProceed() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;

    if (!mounted) return;

    if (!hasSeenWelcome) {
      // First time launch: Show Welcome Screen
      await prefs.setBool('has_seen_welcome', true);

      // Handle initial notification if any
      RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        handleNotificationNavigation(initialMessage);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } else {
      // Subsequent launch: Go directly to Main Screen (Guest or User)

      // If authenticated, register device for notifications
      if (authProvider.authStatus == AuthStatus.authenticated) {
        await Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).registerDevice();
      }

      // Handle initial notification if any
      RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        handleNotificationNavigation(initialMessage);
      }

      // Proceed to load data and go to Home
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      try {
        final List<ConnectivityResult> connectivityResult =
            await (Connectivity().checkConnectivity());

        if (connectivityResult.contains(ConnectivityResult.none)) {
          throw Exception('No internet connection. Please check your network.');
        }
      } on MissingPluginException {
        // Ignore
      }

      if (!mounted) return;
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );

      await productProvider.fetchHomeData();

      if (productProvider.error != null) {
        throw Exception(productProvider.error);
      }

      if (productProvider.homeData == null) {
        throw Exception('Failed to load data.');
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                backgroundColor,
                Colors.white,
                Color(0xFFE3F2FD), // Light blue
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: _isLoading ? _buildLoadingState() : _buildErrorState(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Logo section - clean and simple
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Image.asset(
                  'assets/app_icon/ic_launcher.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tagline
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              "Your Health, Our Priority",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: lightTextColor,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const Spacer(flex: 2),

          // Simple loader
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                PharmacyLoader(size: 50, color: primaryColor, strokeWidth: 3.5),
                const SizedBox(height: 24),
                Text(
                  "Loading your daily dose of wellness...",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: lightTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern error icon
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.shade50,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: Colors.red.shade600,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Error title
            Text(
              'Connection Issue',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: darkTextColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Error message card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _error ?? 'An unexpected error occurred.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: lightTextColor,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Modern retry button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _animationController.forward(from: 0.0);
                  _startAppInitialization();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: primaryColor.withValues(alpha: 0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Try Again',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Help button
            TextButton.icon(
              onPressed: () {
                // Add help functionality
              },
              icon: Icon(
                Icons.help_outline_rounded,
                size: 20,
                color: primaryColor,
              ),
              label: Text(
                'Need help?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
