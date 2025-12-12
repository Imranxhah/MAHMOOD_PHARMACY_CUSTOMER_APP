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
import 'package:customer_app/src/features/profile/presentation/screens/change_password_screen.dart'; // Import ChangePasswordScreen

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
      padding: const EdgeInsets.all(AppSizes.p24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppSizes.radius24),
          bottomRight: Radius.circular(AppSizes.radius24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.onPrimary, width: 3),
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.p12),
          Text(
            '${user.firstName} ${user.lastName}',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.p4),
          Text(
            user.email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: AppSizes.p4),
          Text(
            user.mobile,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
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
          icon: const Icon(Icons.logout),
          label: const Text("Logout"),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius12),
            ),
            elevation: 0,
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
