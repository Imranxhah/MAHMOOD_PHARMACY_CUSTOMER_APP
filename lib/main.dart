import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/constants/app_theme.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/product_provider.dart';
import 'src/providers/order_provider.dart';
import 'src/providers/cart_provider.dart';
import 'src/providers/prescription_provider.dart';
import 'src/providers/branch_provider.dart';
import 'src/providers/address_provider.dart';
import 'src/providers/theme_provider.dart'; // Import ThemeProvider
import 'src/features/auth/presentation/screens/welcome_screen.dart';
import 'src/features/home/presentation/main_screen.dart';


void main() {
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // Add ThemeProvider
      ],
      child: Consumer<ThemeProvider>( // Use Consumer for ThemeProvider
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Mahmood Pharmacy',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode, // Use themeProvider's themeMode
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                switch (auth.authStatus) {
                  case AuthStatus.uninitialized:
                    return const Center(child: CircularProgressIndicator());
                  case AuthStatus.unauthenticated:
                    return const WelcomeScreen();
                  case AuthStatus.authenticated:
                    return const MainScreen();
                  default:
                    return const WelcomeScreen();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
