import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_icons.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/di/dependency_utils.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/animation/app_entrance_animation.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/security/presentation/controller/pin_verify_controller.dart';
import 'package:keep_link/features/security/presentation/widget/pin_verify_form.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class DialogUtils {
  static Future<T?> show<T>(
    Widget dialog, {
    Bindings? binding,
    List<Bindings>? bindings,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useSafeArea = true,
    Duration transitionDuration = const Duration(milliseconds: 200),
    Curve transitionCurve = Curves.easeOutBack,
    Transition transition = Transition.zoom,
    List<Type>? autoRemoveControllers,
  }) async {
    binding?.dependencies();

    if (bindings != null) {
      for (final b in bindings) {
        b.dependencies();
      }
    }
    await Future.delayed(Duration.zero);
    final result = await Get.dialog<T>(
      dialog,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? AppColors.black.withOpacityCompat(0.5),
      useSafeArea: useSafeArea,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
    );

    // Cleanup controller sau khi dialog đóng
    if (autoRemoveControllers != null) {
      for (final type in autoRemoveControllers) {
        DependencyUtils.removeByType(type);
      }
    }

    return result;
  }

  static void showProgressDialog() {
    Get.dialog(
      Center(
        child: LoadingAnimationWidget.threeRotatingDots(
          color: AppColors.primary,
          size: 40,
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void showCustomDialog({
    required BuildContext context,
    String? title,
    required Widget widget,
    List<Widget>? actions,
    bool isCheckButtonClose = true,
    TextAlign textAlign = TextAlign.start,
    double? radius = 10,
    AlignmentGeometry alignment = Alignment.center,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius!),
          ),
          contentPadding: EdgeInsets.zero,
          titlePadding: EdgeInsets.zero,
          title: InkWell(
            onTap: () {
              Get.back();
            },
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 14.0, right: 18.0),
                child: isCheckButtonClose
                    ? const Icon(Icons.close, size: 24.0)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          content: SingleChildScrollView(child: ListBody(children: [widget])),
          actions: actions,
        );
      },
    );
  }

  /// Hàm hiển thị Dialog nhập PIN chuẩn hóa
  static Future<bool> showPinDialog({
    VoidCallback? onCompleted,
    VoidCallback? onDismiss,
  }) async {
    final controllerTag = 'pin_dialog_${DateTime.now().microsecondsSinceEpoch}';
    final pinController = Get.put(
      PinVerifyController(initialMode: FromType.confirm),
      tag: controllerTag,
      permanent: true,
    );
    bool isVerified;
    try {
      final result = await DialogUtils.show<bool>(
        barrierColor: AppColors.black.withOpacityCompat(.8),
        transitionDuration: const Duration(milliseconds: 360),
        transitionCurve: Curves.easeOutCubic,
        Dialog(
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: AppColors.transparent,
          child: AppEntranceAnimation(
            delay: const Duration(milliseconds: 35),
            duration: const Duration(milliseconds: 460),
            beginOffset: const Offset(0, .16),
            beginScale: .93,
            curve: Curves.easeOutBack,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: Utils.dimissKeyboard,
              child: PinVerifyForm(
                controller: pinController,
                width: 360,
                margin: EdgeInsets.zero,
                pinSize: 40,
                pinSpacing: 12,
                minimalStyle: true,
                obscureText: true,
                onCompleted: () => Get.back(result: true),
              ),
            ),
          ),
        ),
      );
      isVerified = result == true;
    } finally {
      // Future của Navigator hoàn tất ngay khi pop, trước khi reverse animation
      // của dialog kết thúc. Chờ overlay tháo khỏi cây rồi mới dispose FocusNode.
      await Future.delayed(const Duration(milliseconds: 250));
      if (Get.isRegistered<PinVerifyController>(tag: controllerTag)) {
        Get.delete<PinVerifyController>(tag: controllerTag, force: true);
      }
    }

    if (isVerified) {
      onCompleted?.call();
    } else {
      onDismiss?.call();
    }
    return isVerified;
  }

  static void showAlert({
    required AlertType alertType,
    String? title,
    String? content,
    VoidCallback? onConfirm,
    String confirmText = 'Đồng ý',
    Color? confirmTextColor,
    bool barrierDismissible = true,
  }) {
    final config = _getAlertConfig(alertType);

    Get.dialog(
      barrierDismissible: barrierDismissible,
      Dialog(
        backgroundColor: AppColors.d300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 44, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null && title.isNotEmpty)
                    TextWidget(
                      text: title,
                      textStyle: AppTextStyle.bold18,
                      color: AppColors.white,
                      textAlign: TextAlign.center,
                    ),
                  if (content != null && content.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextWidget(
                      text: content,
                      textAlign: TextAlign.center,
                      size: 14,
                      color: AppColors.n70,
                      height: 1.35,
                    ),
                  ],
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.8,
              color: AppColors.white.withOpacityCompat(0.08),
            ),
            SizedBox(
              height: 48,
              child: InkWell(
                onTap: onConfirm ?? () => Get.back(),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: Center(
                  child: TextWidget(
                    text: confirmText,
                    size: 15,
                    fontWeight: FontWeight.w700,
                    color: confirmTextColor ?? config.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showConfirm({
    required AlertType alertType,
    String? title,
    String? content,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Đồng ý',
    String cancelText = 'Hủy',
    Color? confirmTextColor,
    Color? cancelTextColor,
    bool barrierDismissible = true,
  }) {
    Get.dialog(
      barrierDismissible: barrierDismissible,
      Dialog(
        backgroundColor: AppColors.d300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 44, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null && title.isNotEmpty)
                    TextWidget(
                      text: title,
                      textStyle: AppTextStyle.bold18,
                      color: AppColors.white,
                      textAlign: TextAlign.center,
                    ),
                  if (content != null && content.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextWidget(
                      text: content,
                      textAlign: TextAlign.center,
                      size: 14,
                      color: AppColors.n70,
                      height: 1.35,
                    ),
                  ],
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.8,
              color: AppColors.white.withOpacityCompat(0.08),
            ),
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  if (onCancel != null) ...[
                    Expanded(
                      child: InkWell(
                        onTap: onCancel,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                        ),
                        child: Center(
                          child: TextWidget(
                            text: cancelText,
                            size: 15,
                            fontWeight: FontWeight.w500,
                            color:
                                cancelTextColor ??
                                AppColors.white.withOpacityCompat(0.75),
                          ),
                        ),
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 0.8,
                      color: AppColors.white.withOpacityCompat(0.08),
                    ),
                  ],
                  Expanded(
                    child: InkWell(
                      onTap: onConfirm ?? () => Get.back(),
                      borderRadius: BorderRadius.only(
                        bottomRight: const Radius.circular(16),
                        bottomLeft: onCancel == null
                            ? const Radius.circular(16)
                            : Radius.zero,
                      ),
                      child: Center(
                        child: TextWidget(
                          text: confirmText,
                          size: 15,
                          fontWeight: FontWeight.w700,
                          color:
                              confirmTextColor ??
                              (alertType == AlertType.error ||
                                      alertType == AlertType.warning
                                  ? AppColors.danger
                                  : AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool> showCustomExitConfirm() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Column(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.transparent,
              radius: 30,
              child: Image.asset(
                AppIcons.icLogoLinkeep.path,
                height: 40,
                width: 40,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "AutoFin",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.black,
              ),
            ),
          ],
        ),
        content: const Text(
          "Bạn có muốn thoát ứng dụng không?",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.black87),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(
              "Ở lại",
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Get.back(result: true), // thoát app
            child: const Text(
              "Thoát",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }

  static _AlertConfig _getAlertConfig(AlertType type) {
    switch (type) {
      case AlertType.success:
        return _AlertConfig(
          color: AppColors.success,
          bgColor: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      case AlertType.error:
        return _AlertConfig(
          color: AppColors.error,
          bgColor: AppColors.error,
          icon: Icons.error_outline,
        );
      case AlertType.warning:
        return _AlertConfig(
          color: AppColors.warning,
          bgColor: AppColors.warning,
          icon: Icons.warning_amber_outlined,
        );
    }
  }
}

class _AlertConfig {
  final Color color;
  final Color bgColor;
  final IconData icon;

  _AlertConfig({
    required this.color,
    required this.bgColor,
    required this.icon,
  });
}
