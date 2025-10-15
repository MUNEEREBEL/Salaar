// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // KHANSAAR SALAAR Dark Palette - WCAG AA Compliant
  // Primary: Royal Gold (improved contrast)
  static const Color primaryColor = Color(0xFFE6C547);
  // Secondary: Deep Brown (improved contrast)
  static const Color secondaryColor = Color(0xFFA0522D);
  // Accent: Bright Gold (improved contrast)
  static const Color accentColor = Color(0xFFFFEB3B);
  // Tertiary: Copper (improved contrast)
  static const Color tertiaryColor = Color(0xFFD2691E);
  // Backgrounds
  static const Color darkBackground = Color(0xFF0A0A0A); // Very Dark
  static const Color darkSurface = Color(0xFF1A1A1A); // Dark Surface
  static const Color darkCard = Color(0xFF2A2A2A); // Dark Card
  // Text Colors - WCAG AA Compliant
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color greyColor = Color(0xFFCCCCCC); // Improved contrast
  static const Color darkGreyColor = Color(0xFF888888); // Improved contrast
  static const Color lightGreyColor = Color(0xFFF0F0F0); // Improved contrast
  // Status Colors
  static const Color errorColor = Color(0xFFDC143C); // Crimson
  static const Color successColor = Color(0xFF32CD32); // Lime Green
  static const Color warningColor = Color(0xFFFF8C00); // Dark Orange
  static const Color infoColor = Color(0xFF4169E1); // Royal Blue

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
        error: errorColor,
        background: darkBackground,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: whiteColor,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: greyColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: greyColor),
        hintStyle: const TextStyle(color: greyColor),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: whiteColor, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: whiteColor, fontSize: 24, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: whiteColor, fontSize: 18, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: whiteColor, fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: whiteColor, fontSize: 18, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: whiteColor, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: whiteColor, fontSize: 16),
        bodyMedium: TextStyle(color: greyColor, fontSize: 14),
        bodySmall: TextStyle(color: greyColor, fontSize: 12),
      ),
    );
  }

  // Text styles for easy access
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: whiteColor,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: whiteColor,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: whiteColor,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: whiteColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: whiteColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: greyColor,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: greyColor,
  );

  // Modern Khansaar Salaar Text Styles
  static const TextStyle khansaarTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: primaryColor,
    letterSpacing: 3,
    shadows: [
      Shadow(
        color: primaryColor,
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  );

  static const TextStyle salaarSubtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w300,
    color: whiteColor,
    letterSpacing: 2,
  );

  static const TextStyle modernCardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: whiteColor,
    letterSpacing: 0.5,
  );

  static const TextStyle modernCardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: greyColor,
    height: 1.4,
  );

  static const TextStyle statusText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: whiteColor,
    letterSpacing: 1,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: whiteColor,
    letterSpacing: 1,
  );

  static const TextStyle navigationLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: greyColor,
  );

  // Additional text styles for missing properties
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: whiteColor,
  );

  // Gradient text style
  static TextStyle gradientText(List<Color> colors) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      foreground: Paint()
        ..shader = LinearGradient(colors: colors).createShader(
          const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
        ),
    );
  }

  // Input decoration for forms
  static const InputDecoration inputDecoration = InputDecoration(
    filled: true,
    fillColor: darkCard,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: greyColor, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: errorColor, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: errorColor, width: 2),
    ),
    labelStyle: TextStyle(color: greyColor),
    hintStyle: TextStyle(color: greyColor),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}