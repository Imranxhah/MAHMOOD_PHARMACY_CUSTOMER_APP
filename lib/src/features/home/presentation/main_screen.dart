import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import SystemNavigator
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/cart_provider.dart'; // Import CartProvider
import '../../../constants/app_strings.dart';
import 'home_screen.dart';
import '../../cart/presentation/cart_screen.dart'; // Import CartScreen
import '../../profile/presentation/screens/settings_screen.dart'; // Import SettingsScreen
import '../../branches/presentation/screens/branches_screen.dart'; // Import BranchesScreen
import '../../profile/presentation/screens/my_prescriptions_screen.dart'; // Import MyPrescriptionsScreen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2; // Home is now at index 2, so it's the default

  final List<Widget> _screens = [
    const CartScreen(),
    const MyPrescriptionsScreen(),
    const HomeScreen(), // Home is at index 2
    const BranchesScreen(),
    const SettingsScreen(), // Changed from ProfileScreen to SettingsScreen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _showExitConfirmationDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to exit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex == 2) {
          _showExitConfirmationDialog();
        } else {
          _onItemTapped(2);
        }
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            // Cart - Index 0
            BottomNavigationBarItem(
              icon: Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return Badge(
                    isLabelVisible: cart.itemCount > 0,
                    label: Text('${cart.itemCount}'),
                    backgroundColor: theme.colorScheme.error,
                    child: const Icon(Icons.shopping_cart_outlined),
                  );
                },
              ),
              activeIcon: Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return Badge(
                    isLabelVisible: cart.itemCount > 0,
                    label: Text('${cart.itemCount}'),
                    backgroundColor: theme.colorScheme.error,
                    child: const Icon(Icons.shopping_cart),
                  );
                },
              ),
              label: "Cart",
            ),
            // Prescriptions - Index 1
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: "Prescriptions",
            ),
            // Home - Index 2
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: AppStrings.home,
            ),
            // Branches - Index 3
            const BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: "Branches",
            ),
            // Profile - Index 4
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), // Changed icon to settings
              activeIcon: Icon(Icons.settings),
              label: "Settings", // Changed label to Settings
            ),
          ],
          currentIndex: _selectedIndex,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
          selectedFontSize: 10,
          unselectedFontSize: 10,
        ),
      ),
    );
  }
}
