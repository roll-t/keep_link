import 'package:flutter/material.dart';
import 'package:keep_link/core/config/app_colors.dart';

class AppTheme {
  // ------------------------------
  // LIGHT COLOR SCHEME (OPTIMIZED)
  // ------------------------------
  static final ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: const Color(0xFF333333),
    primaryContainer: const Color(0xFFFDD943),
    onPrimaryContainer: const Color(0xFF333333),
    secondary: const Color(0xFF3B9DFF),
    onSecondary: const Color(0xFFFFFFFF),
    error: Colors.redAccent,
    onError: Colors.white,
    surface: AppColors.l200,
    onSurface: const Color(0xFF333333),
    shadow: Colors.black,
  );

  // ------------------------------
  // DARK COLOR SCHEME (OPTIMIZED)
  // ------------------------------
  static final ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: const Color(0xFF191919),
    primaryContainer: const Color(0xFFD0C000),
    onPrimaryContainer: const Color(0xFF000000),
    secondary: const Color(0xFF3B9DFF),
    onSecondary: const Color(0xFF000000),
    error: Colors.redAccent,
    onError: Colors.black,
    errorContainer: Colors.redAccent,
    surface: AppColors.d500,
    onSurface: Colors.white,
    shadow: Colors.black,
  );

  // ------------------------------
  // THEME DATA (HIGHLY OPTIMIZED)
  // ------------------------------
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    // fontFamily: 'Poppins',
    colorScheme: lightColorScheme,
    scaffoldBackgroundColor: AppColors.l100,
    appBarTheme: AppBarTheme(
      backgroundColor: lightColorScheme.surface,
      foregroundColor: lightColorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    // fontFamily: 'Poppins',
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: AppColors.d700,
    appBarTheme: AppBarTheme(
      backgroundColor: darkColorScheme.surface,
      foregroundColor: darkColorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
    ),
  );

  static final ThemeData transparent = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: darkColorScheme.copyWith(surface: Colors.transparent),
  );
}
