// lib/theme/app_theme.dart
// Premium dark theme inspired by Nike Run Club, Strava, Apple Fitness+

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ============================================
  // PREMIUM COLOR PALETTE
  // ============================================

  // Background Colors - "Deep Space Black"
  static const Color background = Color(0xFF000000); // True OLED Black
  static const Color surface = Color(0xFF1C1C1E); // Apple Card Dark Gray
  static const Color elevated = Color(0xFF2C2C2E); // Lighter Gray for elevation
  static const Color card = Color(0xFF1C1C1E);

  // Brand Accents
  static const Color primary = Color(0xFFFF6B4A); // Nike Coral/Orange
  static const Color primaryLight = Color(0xFFFF8A6D);
  static const Color primaryDark = Color(0xFFE55A3A);

  // Functional Colors
  static const Color secondary = Color(0xFF32ADE6); // Apple Blue
  static const Color success = Color(0xFF30D158); // Apple Green
  static const Color error = Color(0xFFFF453A); // Apple Red
  static const Color warning = Color(0xFFFF9F0A); // Apple Orange

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93); // System Gray
  static const Color textMuted = Color(0xFF48484A);

  // Separator
  static const Color separator = Color(0xFF38383A);

  // Legacy support
  static const Color primaryBlue = secondary;
  static const Color primaryBlack = background;

  // ============================================
  // HAPTIC FEEDBACK
  // ============================================
  static void hapticLight() => HapticFeedback.lightImpact();
  static void hapticMedium() => HapticFeedback.mediumImpact();
  static void hapticHeavy() => HapticFeedback.heavyImpact();
  static void hapticSelection() => HapticFeedback.selectionClick();

  // ============================================
  // DARK THEME (Main)
  // ============================================

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Inter',

    // Color Scheme
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    ),

    scaffoldBackgroundColor: background,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
        letterSpacing: -0.4,
      ),
    ),

    // Cards - Clean Borderless Look (Progress Screen Style)
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none, // Clean look
      ),
    ),

    // Inputs - Minimalist
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: elevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error.withValues(alpha: 0.5), width: 1.5),
      ),
      hintStyle: TextStyle(
        color: textSecondary.withValues(alpha: 0.6),
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.all(16),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
          letterSpacing: -0.2,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
          letterSpacing: -0.2,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    ),

    // Navigation Bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface.withValues(alpha: 0.9),
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
      selectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        fontFamily: 'Inter',
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Typography - Updated to match Progress Screen tightness
    textTheme: const TextTheme(
      // Large Titles
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -1.0,
        fontFamily: 'Inter',
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.8,
        fontFamily: 'Inter',
      ),
      // Section Headers
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
        fontFamily: 'Inter',
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.4,
        fontFamily: 'Inter',
      ),
      // Body Text
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        letterSpacing: -0.2,
        fontFamily: 'Inter',
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        fontFamily: 'Inter',
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        fontFamily: 'Inter',
      ),
    ),

    // Other
    dividerTheme: const DividerThemeData(color: separator, thickness: 0.5),

    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        fontFamily: 'Inter',
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: elevated,
      contentTextStyle: const TextStyle(
        color: textPrimary,
        fontFamily: 'Inter',
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // Set lightTheme to darkTheme (App is Dark Mode Only)
  static ThemeData lightTheme = darkTheme;
}
