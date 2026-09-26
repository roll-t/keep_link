import 'package:flutter/material.dart';

export 'app_gradients.dart';

/// Single source of truth for every color used by the app.
///
/// The palette is anchored to the dark blue-black Home screen. Feature code
/// must consume these tokens instead of declaring [Color] values directly.
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

  /// Shared surface for the Home header controls and bottom navigation dock.
  static const Color navigationSurface = Color(0xFF1C202B);

  /// Deeper blue-black surface for modal cards over dimmed content.
  static const Color modalSurface = Color(0xFF12161E);

  /// Near-black input surface sampled from the Home palette.
  static const Color inputSurface = Color(0xFF101215);

  /// Extra surfaces used by media, cards and overlays.
  static const Color surfaceDeep = Color(0xFF121212);
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  static const Color surfaceMuted = Color(0xFF1E1F24);
  static const Color surfaceHigh = Color(0xFF2C2E35);
  static const Color divider = Color(0xFF2E2E2E);

  /// Ambient Home background gradient and glow colors.
  static const Color ambientBlue = Color(0xFF0A1019);
  static const Color ambientPlum = Color(0xFF100D13);
  static const Color ambientIndigo = Color(0xFF6D5CFF);
  static const Color ambientPink = Color(0xFFE62996);
  static const Color gradientTransparent = Color(0x00101422);
  static const Color gradientMid = Color(0x66101422);
  static const Color gradientStrong = Color(0xE60E0E0E);

  /// Airy, luminous blue for highlights and actions - #a4c9ff
  static const Color primary = Color(0xFF2A79CB);

  /// Darker blue for gradient effects - #7da8d8
  static const Color primaryDim = Color(0xFF4C93E7);

  /// Lighter blue for containers - #cde4ff
  static const Color primaryContainer = Color(0xFFcde4ff);

  /// Brighter variants for gradients, focus rings and QR accents.
  static const Color primaryBright = Color(0xFF79B8FF);
  static const Color primaryFocus = Color(0xFF77B8FF);
  static const Color secondary = Color(0xFF3B9DFF);
  static const Color brand = Color(0xFF0068FF);

  /// Primary text/content - #e7e5e5
  static const Color onSurface = Color(0xFFe7e5e5);

  /// Secondary text - dim variant - #b8b6b6
  static const Color onSurfaceVariant = Color(0xFFb8b6b6);

  /// Outline for borders at 15% opacity - #7f7d7d
  static const Color outlineVariant = Color(0xFF7f7d7d);

  /// Constant opacity tokens keep const widgets const-safe.
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white38 = Color(0x61FFFFFF);
  static const Color white24 = Color(0x3DFFFFFF);
  static const Color white12 = Color(0x1FFFFFFF);
  static const Color black87 = Color(0xDE000000);

  /// Semantic feedback colors.
  static const Color danger = Color(0xFFFF4D4F);
  static const Color dangerBright = Color(0xFFFF4444);
  static const Color successBright = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF1A6B3C);
  static const Color amber = Color(0xFFFFB300);
  static const Color qrYellow = Color(0xFFFFD32A);
  static const Color info = Color(0xFF2A79CB);
  static const Color infoMuted = Color(0xFF607D8B);

  /// Optional content accents. They remain centralized even when a feature
  /// needs a distinct identity (for example QR templates).
  static const Color accentPink = Color(0xFFE84393);
  static const Color accentPurple = Color(0xFF6C5CE7);
  static const Color accentViolet = Color(0xFF916BFF);
  static const Color accentOrchid = Color(0xFF9B59B6);

  /// Light surfaces used by exported QR cards.
  static const Color lightCanvas = Color(0xFFF4F5F8);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color mediaTextMuted = Color(0xFFA0A0A0);

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

  /// Low-contrast skeleton palette for the dark interface.
  static const Color shimmerBase = Color(0xFF202124);
  static const Color shimmerHighlight = Color.fromARGB(255, 34, 35, 38);
  static const Color shimmerSingleColor = Color(0xFF25272B);
}
