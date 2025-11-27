import 'dart:ui';

extension ColorCompat on Color {
  // Dùng thay cho .withOpacity(x)
  Color withOpacityCompat(double opacity) {
    return withValues(alpha: opacity);
  }

  // Rút gọn ColorFilter.mode(...)
  ColorFilter toColorFilter([BlendMode mode = BlendMode.srcIn]) {
    return ColorFilter.mode(this, mode);
  }
}