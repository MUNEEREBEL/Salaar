// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true; // Default to dark mode

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.grey[50],
      cardColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: Colors.grey[900],
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Colors.grey[800],
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: Colors.grey[700]),
        bodyMedium: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppTheme.darkBackground,
      cardColor: AppTheme.darkSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: AppTheme.darkBackground,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: AppTheme.whiteColor,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppTheme.whiteColor,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: AppTheme.whiteColor),
        bodyMedium: TextStyle(color: Colors.grey[300]),
      ),
    );
  }
}
