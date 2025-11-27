import 'package:flutter/material.dart';
import 'package:keep_link/core/const/app_colors.dart';
import 'package:keep_link/core/extension/colors.dart';

class AppTheme {
  static var theme1 = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: Color(0xFFFFD9D7),
      surface: Color.fromRGBO(255, 255, 255, 1),
      onSurface: Colors.black,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFEB9B7),
      selectedItemColor: Color(0x00ff0000),
      unselectedItemColor: Color(0xFFFEB9B7),
    ),

  );
  static var theme2 = ThemeData(
    primaryColor: const Color(0xFFB20845),
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFFB20845),
      secondary: const Color(0xFF62CDFA).withOpacityCompat(0.17),
      surface: const Color(0xFFEAF8FE),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF5DCCFC),
      selectedItemColor: Color(0x00ff0000),
      unselectedItemColor: Color(0xFF5DCCFC),
    ),
  );
}
