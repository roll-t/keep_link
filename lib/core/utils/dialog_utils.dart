import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/config/app_images.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/core/ui/button/primary_button.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/security/application/di/pin_verify_binding.dart';
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
      Center(child: LoadingAnimationWidget.threeRotatingDots(color: AppColors.primary, size: 40)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius!)),
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
  static Future<dynamic> showPinDialog({required Function() onCompleted, VoidCallback? onDismiss}) {
    return DialogUtils.show(
      barrierColor: AppColors.black.withOpacityCompat(.8),
      GestureDetector(
        onTap: () {
          final isKeyboardVisible = MediaQuery.of(Get.context!).viewInsets.bottom > 0;
          if (isKeyboardVisible) {
            Utils.dimissKeyboard();
          } else {
            Get.back();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.transparent,
          body: Center(child: PinVerifyForm(onCompleted: onCompleted)),
        ),
      ),
      binding: PinVerifyBinding(),
    ).then((value) {
      // Callback khi dialog đóng hẳn
      onDismiss?.call();
      return value;
    });
  }

  static void showAlert({
    required AlertType alertType,
    String? title,
    String? content,
    VoidCallback? onConfirm,
    String confirmText = 'Đồng ý',
    bool barrierDismissible = true,
  }) {
    final config = _getAlertConfig(alertType);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: config.bgColor.withValues(alpha: .2),
                radius: 24,
                child: Icon(config.icon, color: config.color, size: 28),
              ),
              const SizedBox(height: 8),
              TextWidget(text: title ?? 'Thông báo', textStyle: AppTextStyle.semiBold16),
              const SizedBox(height: 12),
              TextWidget(text: content ?? '', textAlign: TextAlign.center, size: 14),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: confirmText,
                      isMaxParent: true,
                      onPressed:
                          onConfirm ??
                          () {
                            Get.back();
                          },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: barrierDismissible,
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
    bool barrierDismissible = true,
  }) {
    final config = _getAlertConfig(alertType);

    Get.dialog(
      barrierDismissible: barrierDismissible,
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: config.bgColor.withValues(alpha: .2),
                radius: 24,
                child: Icon(config.icon, color: config.color, size: 28),
              ),
              const SizedBox(height: 8),
              TextWidget(text: title ?? 'Thông báo', textStyle: AppTextStyle.semiBold16),
              const SizedBox(height: 12),
              TextWidget(text: content ?? '', textAlign: TextAlign.center, size: 14),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (onCancel != null)
                    Expanded(
                      child: PrimaryButton(
                        backgroundColor: AppColors.d300,
                        text: cancelText,
                        isMaxParent: true,
                        onPressed: onCancel,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      text: confirmText,
                      isMaxParent: true,
                      onPressed: onConfirm ?? () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
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
              backgroundColor: Colors.transparent,
              radius: 30,
              child: Image.asset(AppImages.iLogo.path, height: 40, width: 40),
            ),
            const SizedBox(height: 12),
            const Text(
              "AutoFin",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
            ),
          ],
        ),
        content: const Text(
          "Bạn có muốn thoát ứng dụng không?",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(
              "Ở lại",
              style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Get.back(result: true), // thoát app
            child: const Text(
              "Thoát",
              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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

  _AlertConfig({required this.color, required this.bgColor, required this.icon});
}
