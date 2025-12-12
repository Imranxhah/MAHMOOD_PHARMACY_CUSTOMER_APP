import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  void _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? theme = prefs.getString('themeMode');
    if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  void toggleTheme(bool isDarkMode) {
    if (isDarkMode) {
      _themeMode = ThemeMode.dark;
      _saveThemeMode('dark');
    } else {
      _themeMode = ThemeMode.light;
      _saveThemeMode('light');
    }
    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    _saveThemeMode('system');
    notifyListeners();
  }

  void _saveThemeMode(String theme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('themeMode', theme);
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Logic to check system brightness (not directly accessible in Provider)
      // For simplicity, we'll assume it's light unless explicitly set to dark.
      // In a real app, you'd use MediaQuery.of(context).platformBrightness
      // But ThemeProvider doesn't have context. So it's best to handle
      // ThemeMode.system as a pass-through to MaterialApp.
      // For the toggle, we'll just consider ThemeMode.dark as the "dark mode on" state.
      return false; // Will be determined by system at MaterialApp level
    }
    return _themeMode == ThemeMode.dark;
  }
}
