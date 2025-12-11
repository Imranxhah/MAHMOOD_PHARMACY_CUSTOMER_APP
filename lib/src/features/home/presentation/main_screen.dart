import 'package:flutter/material.dart';
import '../../../constants/app_strings.dart';
import 'home_screen.dart';
import '../../products/presentation/product_list_screen.dart';
import '../../profile/presentation/screens/profile_screen.dart';
import '../../branches/presentation/screens/branches_screen.dart'; // Import BranchesScreen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ProductListScreen(),
    const BranchesScreen(), // New 'Locate Store' screen
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: AppStrings.search),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined), // Icon for Locate Store
            activeIcon: Icon(Icons.location_on),
            label: AppStrings.locateStore, // Label for Locate Store
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: AppStrings.profile,
          ),
        ],
        currentIndex: _selectedIndex,
        // selectedItemColor: AppColors.primary, // Handled by FlexColorScheme
        // unselectedItemColor: AppColors.grey, // Handled by FlexColorScheme
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
