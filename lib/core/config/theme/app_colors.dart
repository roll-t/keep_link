import 'package:flutter/material.dart';

/// High-End Dark Mode Design System Colors
/// Based on "The Digital Curator" design philosophy
class AppColors {
  // ========================================
  // DESIGN SYSTEM COLORS (Primary Palette)
  // ========================================

  /// Deep immersive base canvas - #0e0e0e
  static const Color background = Color(0xFF0e0e0e);

  /// Primary surface for main content - #1a1a1a
  static const Color surface = Color(0xFF1a1a1a);

  /// Subtle section dividers and grouped elements - #131313
  static const Color surfaceContainerLow = Color(0xFF131313);

  /// High-impact interactive elements like search bars - #252626
  static const Color surfaceContainerHighest = Color(0xFF252626);

  /// Airy, luminous blue for highlights and actions - #a4c9ff
  static const Color primary = Color(0xFF2A79CB);

  /// Darker blue for gradient effects - #7da8d8
  static const Color primaryDim = Color(0xFF4C93E7);

  /// Lighter blue for containers - #cde4ff
  static const Color primaryContainer = Color(0xFFcde4ff);

  /// Primary text/content - #e7e5e5
  static const Color onSurface = Color(0xFFe7e5e5);

  /// Secondary text - dim variant - #b8b6b6
  static const Color onSurfaceVariant = Color(0xFFb8b6b6);

  /// Outline for borders at 15% opacity - #7f7d7d
  static const Color outlineVariant = Color(0xFF7f7d7d);

  // ========================================
  // LEGACY COLORS (For Compatibility)
  // ========================================
  static const Color bg700 = Color(0xFF0e0e0e); // Maps to background
  static const Color bg500 = Color(0xFF1a1a1a); // Maps to surface

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFffffff);
  static const Color grey = Color(0xFF8890A6);
  static const Color accent = Color(0xFFe67e22);

  static const Color green = Color(0xFF00AC67);
  static const Color blue = Color.fromARGB(255, 0, 39, 214);
  static const Color red = Color(0xFFeb2f06);
  static const Color yellow = Color(0xFFe58e26);
  static const Color transparent = Color.fromARGB(0, 8, 19, 17);

  static const Color warning = Color(0xFFfa983a);
  static const Color error = Color(0xFFeb2f06);
  static const Color success = Color(0xFF2ed573);

  // Dark palette (legacy naming, maps to design system)
  static const Color d700 = Color(0xFF0e0e0e); // background
  static const Color d500 = Color(0xFF1a1a1a); // surface
  static const Color d300 = Color(0xff252626); // surfaceContainerHighest
  static const Color d200 = Color(0xff3f3f3f);
  static const Color d100 = Color(0xff575757);

  // Light palette
  static const l300 = Color.fromARGB(255, 218, 216, 216);
  static const l200 = Color.fromARGB(255, 238, 238, 238);
  static const l100 = Color.fromARGB(255, 255, 255, 255);

  // Text colors (legacy naming)
  static const t800 = Color(0xFF000000);
  static const t700 = Color(0xFF333333);
  static const t600 = Color(0xFF4F4F4F);
  static const t500 = Color(0xFF585858);
  static const t400 = Color(0xFF828282);
  static const t300 = Color(0xFFBDBDBD);
  static const t200 = Color(0xFFE0E0E0);
  static const t100 = Color(0xFFF5F5F5);

  // Neutral colors
  static const n0 = Color(0xFFFFFFFF);
  static const n10 = Color(0xFFFAFAFB);
  static const n15 = Color(0xFFE5E5EF);
  static const n20 = Color(0xFFF6F6F6);
  static const n30 = Color(0xFFEDEDED);
  static const n40 = Color(0xFFE1E1E2);
  static const n50 = Color(0xFFC6C6C8);
  static const n60 = Color(0xFFB8B8BA);
  static const n70 = Color(0xFFADADAF);
  static const n80 = Color(0xFF9F9FA2);
  static const n90 = Color(0xFF929295);
  static const n100 = Color(0xFF848488);
  static const n200 = Color(0xFF76767A);
  static const n300 = Color(0xFF69696D);
  static const n400 = Color(0xFF5D5D62);
  static const n500 = Color(0xFF4F4F55);
  static const n600 = Color(0xFF44444A);
  static const n700 = Color(0xFF34343A);
  static const n800 = Color(0xFF26262D);
  static const n900 = Color(0xFF1B1B22);

  static const Color shimmerBase = Color.fromARGB(255, 218, 218, 218);
  static const Color shimmerHighlight = Color.fromARGB(255, 238, 238, 238);
  static const Color shimmerSingleColor = Color(0xFFBBDEFB);
}
