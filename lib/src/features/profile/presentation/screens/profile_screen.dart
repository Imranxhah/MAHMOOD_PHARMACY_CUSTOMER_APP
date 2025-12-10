import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/constants/app_sizes.dart';
import 'package:customer_app/src/constants/app_strings.dart';
import 'package:customer_app/src/features/auth/presentation/screens/welcome_screen.dart';
import 'package:customer_app/src/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:customer_app/src/features/admin/presentation/screens/user_list_screen.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${AppStrings.nameLabel}${user.firstName} ${user.lastName}'),
                  const SizedBox(height: AppSizes.p8),
                  Text('${AppStrings.emailLabel}${user.email}'),
                  const SizedBox(height: AppSizes.p8),
                  Text('${AppStrings.mobileLabel}${user.mobile}'),
                  const SizedBox(height: AppSizes.p20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      );
                    },
                    child: const Text(AppStrings.editProfile),
                  ),
                  if (authProvider.isAdmin) ...[
                    const SizedBox(height: AppSizes.p20),
                    ElevatedButton(
                      onPressed: () {
                         Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UserListScreen()),
                        );
                      },
                      child: const Text(AppStrings.viewAllUsers),
                    ),
                  ]
                ],
              ),
            ),
    );
  }
}
