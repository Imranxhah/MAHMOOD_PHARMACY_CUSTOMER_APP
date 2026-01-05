import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/providers/theme_provider.dart';
import 'package:customer_app/src/constants/app_sizes.dart';
import 'package:customer_app/src/constants/app_strings.dart';
import 'package:customer_app/src/features/auth/presentation/screens/welcome_screen.dart';
import 'package:customer_app/src/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:customer_app/src/features/profile/presentation/screens/wishlist_screen.dart';
import 'package:customer_app/src/features/admin/presentation/screens/user_list_screen.dart';
import 'package:customer_app/src/features/profile/presentation/screens/my_prescriptions_screen.dart';
import 'package:customer_app/src/features/branches/presentation/screens/branches_screen.dart';
import 'package:customer_app/src/features/profile/presentation/screens/address_list_screen.dart';
import 'package:customer_app/src/features/profile/presentation/order_history_screen.dart';
import 'package:customer_app/src/features/profile/presentation/screens/change_password_screen.dart';
import 'package:customer_app/src/common_widgets/web_view_screen.dart'; // Import WebViewScreen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);
    final isAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white, // Use onSurface for visibility
          ),
        ),
        elevation: 0,
      ),
      body: (isAuthenticated && user == null)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header Card (Only if authenticated)
                  if (isAuthenticated && user != null)
                    _buildProfileHeader(context, user, theme),

                  const SizedBox(height: AppSizes.p16),

                  // Account Section
                  _buildSectionTitle(context, "Account", theme),
                  _buildMenuCard(context, theme, [
                    if (isAuthenticated) ...[
                      _MenuItem(
                        icon: Icons.edit_outlined,
                        title: AppStrings.editProfile,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.history,
                        title: AppStrings.orderHistory,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrderHistoryScreen(),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.favorite_outline,
                        title: AppStrings.favorites,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WishlistScreen(),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.receipt_long_outlined,
                        title: AppStrings.myPrescriptions,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyPrescriptionsScreen(),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.location_on_outlined,
                        title: "My Addresses",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddressListScreen(),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.lock_outline,
                        title: "Change Password",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        ),
                      ),
                    ] else ...[
                      _MenuItem(
                        icon: Icons.login,
                        title: "Login",
                        onTap: () => Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const WelcomeScreen(),
                          ),
                          (route) => false,
                        ),
                      ),
                    ],
                  ]),

                  const SizedBox(height: AppSizes.p16),

                  // General Section
                  _buildSectionTitle(context, "General", theme),
                  _buildMenuCard(context, theme, [
                    _MenuItem(
                      icon: Icons.store_outlined,
                      title: AppStrings.ourBranches,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BranchesScreen(),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: AppSizes.p16),

                  // Legal & Support Section
                  _buildSectionTitle(context, "Legal & Support", theme),
                  _buildMenuCard(context, theme, [
                    _MenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: "Privacy Policy",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WebViewScreen(
                            title: "Privacy Policy",
                            url:
                                "https://mahmoodpharmacy.com.pk/privacy-policy/",
                          ),
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.description_outlined,
                      title: "Terms of Service",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WebViewScreen(
                            title: "Terms of Service",
                            url:
                                "https://mahmoodpharmacy.com.pk/terms-of-service/",
                          ),
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.warning_amber_rounded,
                      title: "Disclaimer",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WebViewScreen(
                            title: "Disclaimer",
                            url: "https://mahmoodpharmacy.com.pk/disclaimer/",
                          ),
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.support_agent_rounded,
                      title: "Contact Us",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WebViewScreen(
                            title: "Contact Us",
                            url:
                                "https://mahmoodpharmacy.com.pk/complaint-form/",
                          ),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: AppSizes.p16),

                  // Admin Section (if admin and authenticated)
                  if (isAuthenticated && authProvider.isAdmin) ...[
                    _buildSectionTitle(context, "Admin", theme),
                    _buildMenuCard(context, theme, [
                      _MenuItem(
                        icon: Icons.people_outline,
                        title: AppStrings.viewAllUsers,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserListScreen(),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: AppSizes.p16),
                  ],

                  // Preferences Section
                  _buildSectionTitle(context, "Preferences", theme),
                  _buildThemeCard(context, theme),

                  const SizedBox(height: AppSizes.p24),

                  // Logout Button (Only if authenticated)
                  if (isAuthenticated) ...[
                    _buildLogoutButton(context, authProvider, theme),
                    const SizedBox(height: AppSizes.p32),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user, ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radius24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radius24),
        child: Stack(
          children: [
            // Decorative circles in background - clipped properly
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.onPrimary.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.onPrimary.withOpacity(0.06),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.p16, // Reduced vertical padding
                horizontal: AppSizes.p24,
              ),
              child: Column(
                children: [
                  // Profile Avatar with initials
                  Stack(
                    children: [
                      // Outer glow ring
                      Container(
                        width: 80, // Reduced from 100
                        height: 80, // Reduced from 100
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.onPrimary.withOpacity(0.3),
                              theme.colorScheme.onPrimary.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 70, // Reduced from 88
                            height: 70, // Reduced from 88
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.surface,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.brightness == Brightness.dark
                                        ? const Color(0xFF2E3440)
                                        : const Color(0xFFF8F9FA),
                                    theme.brightness == Brightness.dark
                                        ? const Color(0xFF3B4252)
                                        : const Color(0xFFFFFFFF),
                                  ],
                                ),
                                border: Border.all(
                                  color: theme.brightness == Brightness.dark
                                      ? theme.colorScheme.onPrimary.withOpacity(
                                          0.2,
                                        )
                                      : theme.colorScheme.primary.withOpacity(
                                          0.15,
                                        ),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${user.firstName[0].toUpperCase()}${user.lastName[0].toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 24, // Reduced from 32
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                    letterSpacing: 2,
                                    foreground: Paint()
                                      ..shader =
                                          LinearGradient(
                                            colors:
                                                theme.brightness ==
                                                    Brightness.dark
                                                ? [
                                                    theme.colorScheme.onPrimary,
                                                    theme.colorScheme.onPrimary
                                                        .withOpacity(0.8),
                                                  ]
                                                : [
                                                    theme.colorScheme.primary,
                                                    theme.colorScheme.primary
                                                        .withOpacity(0.7),
                                                  ],
                                          ).createShader(
                                            const Rect.fromLTWH(0, 0, 200, 70),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.p12), // Reduced from p16

                  // User name with verified badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          '${user.firstName} ${user.lastName}',
                          style: theme.textTheme.titleLarge?.copyWith( // Changed to titleLarge for slightly smaller text
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSizes.p8),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified,
                          size: 14, // Reduced from 16
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.p8), // Reduced from p12

                  // Contact info cards
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p12, // Reduced from p16
                      vertical: AppSizes.p8, // Reduced from p12
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                      border: Border.all(
                        color: theme.colorScheme.onPrimary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Email
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: theme.colorScheme.onPrimary.withOpacity(
                                0.9,
                              ),
                            ),
                            const SizedBox(width: AppSizes.p8),
                            Flexible(
                              child: Text(
                                user.email,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary
                                      .withOpacity(0.95),
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSizes.p8),

                        // Divider
                        Container(
                          height: 1,
                          color: theme.colorScheme.onPrimary.withOpacity(0.2),
                        ),

                        const SizedBox(height: AppSizes.p8),

                        // Phone
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: theme.colorScheme.onPrimary.withOpacity(
                                0.9,
                              ),
                            ),
                            const SizedBox(width: AppSizes.p8),
                            Text(
                              user.mobile,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimary.withOpacity(
                                  0.95,
                                ),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p8,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    ThemeData theme,
    List<_MenuItem> items,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(
          items.length,
          (index) => Column(
            children: [
              _buildMenuItem(context, theme, items[index]),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  indent: AppSizes.p48, // Changed from p56 to p48
                  color: theme.dividerColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, ThemeData theme, _MenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p16,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                ),
                child: Icon(
                  item.icon,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSizes.p16),
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p16,
              vertical: AppSizes.p12,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                  ),
                  child: Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSizes.p16),
                Expanded(
                  child: Text(
                    "Dark Mode",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(value),
                  activeTrackColor: theme
                      .colorScheme
                      .primary, // Changed from activeColor to activeTrackColor
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    AuthProvider authProvider,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text("Logout", style: theme.textTheme.titleLarge),
                content: Text(
                  "Are you sure you want to logout?",
                  style: theme.textTheme.bodyMedium,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      authProvider.logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: Text(
                      "Logout",
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p16,
              vertical: AppSizes.p16,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 22,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: AppSizes.p16),
                Expanded(
                  child: Text(
                    "Logout",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItem({required this.icon, required this.title, required this.onTap});
}
