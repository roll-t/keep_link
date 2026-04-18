import 'package:flutter/material.dart';
import 'package:keep_link/core/config/app_colors.dart';

class AppTheme {
  // ========================================
  // LIGHT COLOR SCHEME
  // ========================================
  static final ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: const Color(0xFF1a1a1a),
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: const Color(0xFF1a1a1a),
    secondary: const Color(0xFF3B9DFF),
    onSecondary: const Color(0xFFFFFFFF),
    error: Colors.redAccent,
    onError: Colors.white,
    surface: AppColors.l200,
    onSurface: const Color(0xFF333333),
    shadow: Colors.black,
    outline: AppColors.outlineVariant,
    outlineVariant: AppColors.outlineVariant,
  );

  // ========================================
  // DARK COLOR SCHEME (Design System)
  // ========================================
  static final ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    // Primary Blue - Luminous and calm
    primary: AppColors.primary,
    onPrimary: AppColors.background,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.background,
    // Secondary
    secondary: AppColors.primaryDim,
    onSecondary: AppColors.onSurface,
    // Error
    error: Colors.redAccent,
    onError: Colors.white,
    errorContainer: Colors.redAccent,
    // Surface - Using design system colors
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainer: AppColors.surfaceContainerLow,
    // Variants
    outlineVariant: AppColors.outlineVariant.withOpacity(0.15),
    // Shadow
    shadow: Colors.black,
  );

  // ========================================
  // LIGHT THEME
  // ========================================
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    scaffoldBackgroundColor: AppColors.l100,
    appBarTheme: AppBarTheme(
      backgroundColor: lightColorScheme.surface,
      foregroundColor: lightColorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
    ),
  );

  // ========================================
  // DARK THEME (Design System)
  // ========================================
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      centerTitle: true,
    ),
    // Card styling
    cardTheme: CardThemeData(
      color: AppColors.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
      hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
    ),
  );

  // ========================================
  // TRANSPARENT THEME
  // ========================================
  static final ThemeData transparent = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: darkColorScheme.copyWith(surface: Colors.transparent),
  );
}
