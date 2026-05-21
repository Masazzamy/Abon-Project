import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Colors based on Abon Theme (Golden Brown & White)
  static const Color primaryBrown = Color(0xFF8C5228);      // Abon Golden Brown
  static const Color accentGold = Color(0xFFD4A35B);        // Golden Yellow Highlight
  static const Color primaryBrownLight = Color(0xFFA66D44); // Light warm brown
  static const Color primaryBrownDark = Color(0xFF5C3314);  // Dark brown for depth
  
  static const Color textPrimary = Color(0xFF2C2C2C);       // Dark charcoal text
  static const Color textSecondary = Color(0xFF757575);     // Neutral grey text
  static const Color bgLight = Colors.white;                // Clean white background
  static const Color surfaceWhite = Colors.white;
  
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color successGreen = Color(0xFF388E3C);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBrown,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primaryBrown,
        onPrimary: Colors.white,
        secondary: accentGold,
        onSecondary: Colors.white,
        surface: surfaceWhite,
        onSurface: textPrimary,
        error: errorRed,
        onError: Colors.white,
      ),
      
      // Typography
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryBrownDark,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryBrownDark,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryBrown,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFAF6F0), // Very light soft cream
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: primaryBrown, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0D8CE), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0D8CE), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBrown, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrown, // Golden brown button
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryBrown.withAlpha(76), // 30% opacity -> 76 alpha
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBrown,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 4,
        shadowColor: primaryBrown.withAlpha(25), // 10% opacity -> 25 alpha
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
