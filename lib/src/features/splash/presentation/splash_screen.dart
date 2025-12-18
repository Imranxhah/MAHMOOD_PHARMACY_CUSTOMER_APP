import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:customer_app/src/features/home/presentation/main_screen.dart';
import 'package:customer_app/src/features/auth/presentation/screens/welcome_screen.dart';
import 'package:customer_app/src/providers/product_provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/providers/notification_provider.dart';
import 'package:awesome_notifications/awesome_notifications.dart'; // Import awesome_notifications
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:customer_app/main.dart'; // Ensure this exports handleNotificationNavigation

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
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAppInitialization();
    AwesomeNotifications().resetGlobalBadge(); // Clear badge on app start
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );

    _animationController.forward();
  }

  Future<void> _startAppInitialization() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.authStatus != AuthStatus.uninitialized) {
      await _checkAuthAndProceed();
    } else {
      authProvider.addListener(_authListener);
    }
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

    if (authProvider.authStatus == AuthStatus.unauthenticated) {
      if (!mounted) return;
      
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        handleNotificationNavigation(initialMessage);
      }
      
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } else if (authProvider.authStatus == AuthStatus.authenticated) {
      if (!mounted) return;
      await Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).registerDevice();
      
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        handleNotificationNavigation(initialMessage);
      }
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.1),
                colorScheme.surface,
                colorScheme.primaryContainer.withValues(alpha: 0.15),
              ],
              stops: const [0.0, 0.5, 1.0],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SizedBox(
                width: 140,
                height: 140,
                child: Center(
                  child: Image.asset(
                    'assets/images/splash_screen.png',
                    width: 170,
                    height: 170,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    "MPharmacy",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your Health, Our Priority",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 60),

          FadeTransition(
            opacity: _fadeAnimation,
            child: SizedBox(
              width: 200,
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 2000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: colorScheme.primaryContainer
                            .withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Loading your experience...",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.errorContainer.withValues(alpha: 0.3),
                          colorScheme.errorContainer.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.cloud_off_rounded,
                      size: 72,
                      color: colorScheme.error,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            Text(
              'Connection Issue',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                _error ?? 'An unexpected error occurred.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _animationController.forward(from: 0.0);
                _loadData();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
            ),

            const SizedBox(height: 16),

            TextButton.icon(
              onPressed: () {
              },
              icon: Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
              label: Text(
                'Need help?',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
