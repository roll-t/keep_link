import 'package:flutter/material.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';

class AppGradients {
  /// Gradient trắng chuyển tiếp từ trong suốt ở đỉnh xuống trắng ở đáy thẻ
  static final LinearGradient bgWhiteGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.white.withOpacityCompat(0.0),
      AppColors.white.withOpacityCompat(0.60),
      AppColors.white.withOpacityCompat(0.88),
      AppColors.white.withOpacityCompat(0.96),
    ],
    stops: const [0.0, 0.35, 0.70, 1.0],
  );

  /// Gradient đen mờ chuyển tiếp cho overlay hình ảnh
  static final LinearGradient bgDarkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.black.withOpacityCompat(0.0),
      AppColors.black.withOpacityCompat(0.50),
      AppColors.black.withOpacityCompat(0.95),
    ],
    stops: const [0.0, 0.40, 1.0],
  );
}
