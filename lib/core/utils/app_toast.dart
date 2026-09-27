import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';

class AppToast {
  static final FToast _fToast = FToast();

  /// Hàm hiển thị Toast chung với nền và màu chữ đồng nhất
  static void _show({
    required String msg,
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(seconds: 2),
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    final ctx = Get.overlayContext ?? Get.key.currentContext;
    if (ctx == null) return;
    _fToast.init(ctx);
    _fToast.removeCustomToast();

    _fToast.showToast(
      gravity: gravity,
      toastDuration: duration,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.navigationSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.white.withOpacityCompat(0.08)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacityCompat(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? AppColors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: TextWidget(text: msg, color: AppColors.white, size: 14, maxLines: 2),
            ),
          ],
        ),
      ),
    );
  }

  /// Toast trạng thái bình thường (chỉ truyền text, icon tuỳ chọn)
  static void showToast(String msg, [IconData? icon]) {
    _show(msg: msg, icon: icon);
  }

  /// Alias gọi ngắn gọn cho showToast
  static void show(String msg, [IconData? icon]) => showToast(msg, icon);

  /// Toast trạng thái thành công (thêm icon success)
  static void success(String msg) {
    _show(msg: msg, icon: Icons.check_circle_rounded, iconColor: AppColors.success);
  }

  /// Toast trạng thái lỗi (thêm icon error)
  static void error(String msg) {
    _show(msg: msg, icon: Icons.error_outline_rounded, iconColor: AppColors.error);
  }

  /// Toast trạng thái cảnh báo (thêm icon warning)
  static void warning(String msg) {
    _show(msg: msg, icon: Icons.warning_amber_rounded, iconColor: AppColors.warning);
  }

  /// Toast trạng thái thông tin (thêm icon info)
  static void info(String msg) {
    _show(msg: msg, icon: Icons.info_outline_rounded, iconColor: AppColors.primaryDim);
  }
}
