import 'package:flutter/material.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';

class AppTheme {
  // ========================================
  // LIGHT COLOR SCHEME
  // ========================================
  static final ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.surface,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.surface,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    error: AppColors.danger,
    onError: AppColors.white,
    surface: AppColors.l200,
    onSurface: AppColors.t700,
    shadow: AppColors.black,
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
    error: AppColors.danger,
    onError: AppColors.white,
    errorContainer: AppColors.danger,
    // Surface - Using design system colors
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainer: AppColors.surfaceContainerLow,
    // Variants
    outlineVariant: AppColors.outlineVariant.withValues(alpha: 0.15),
    // Shadow
    shadow: AppColors.black,
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
    switchTheme: const SwitchThemeData(
      trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
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
        borderSide: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
      hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
    ),
    // Switch styling - remove default M3 border outline
    switchTheme: const SwitchThemeData(
      trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
    ),
  );

  // ========================================
  // TRANSPARENT THEME
  // ========================================
  static final ThemeData transparent = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.transparent,
    colorScheme: darkColorScheme.copyWith(surface: AppColors.transparent),
  );
}
