import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/security/application/controller/pin_verify_controller.dart';
import 'package:pinput/pinput.dart';

enum FromType { confirm, create, changePassword }

class PinVerifyForm extends StatelessWidget {
  final VoidCallback? onCompleted;
  final FromType fromType;
  final Color? background;
  final Widget? title;
  final double? width;
  final EdgeInsets? margin;
  final bool isDismissDialog;

  const PinVerifyForm({
    super.key,
    this.onCompleted,
    this.background,
    this.fromType = FromType.confirm,
    this.title,
    this.width,
    this.margin,
    this.isDismissDialog = true,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PinVerifyController>(
      builder: (controller) {
        final defaultPinTheme = _buildDefaultPinTheme();
        return Container(
          width: width ?? Get.width,
          margin: margin ?? const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: background ?? AppColors.d300,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Obx(() {
            final isConfirmStep = controller.firstPin.value.isNotEmpty;
            if (fromType == FromType.changePassword) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextWidget(text: "Enter New PIN", textStyle: AppTextStyle.semiBold20),
                  const SizedBox(height: 12),

                  // PIN mới
                  Pinput(
                    autofocus: false,
                    onTapOutside: (event) {
                      Utils.dimissKeyboard();
                    },
                    length: 4,
                    controller: controller.newPinController,
                    focusNode: controller.newPinFocus,
                    defaultPinTheme: defaultPinTheme,
                    onCompleted: (pin) => controller.onCompletedNewPin(pin),
                  ),

                  const SizedBox(height: 28),

                  TextWidget(text: "Confirm PIN", textStyle: AppTextStyle.semiBold20),
                  const SizedBox(height: 12),

                  // Xác nhận PIN
                  Pinput(
                    autofocus: false,
                    length: 4,
                    controller: controller.confirmPinController,
                    focusNode: controller.confirmPinFocus,
                    defaultPinTheme: defaultPinTheme,
                    onCompleted: (pin) => controller.onCompletedConfirmPin(pin),
                  ),
                ],
              );
            }

            final isLocked = controller.isLocked;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...(title != null
                    ? [title!]
                    : [
                        TextWidget(
                          text: (isConfirmStep ? "Confirm PIN" : "Enter PIN"),
                          textStyle: AppTextStyle.semiBold20,
                        ),
                        SizedBox(height: 20),
                      ]),

                Pinput(
                  autofocus: false,
                  length: 4,
                  controller: controller.pinController,
                  focusNode: controller.focusNode,
                  enabled: !isLocked,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: AppColors.primary),
                    ),
                  ),
                  submittedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: AppColors.primary),
                      color: AppColors.d500,
                    ),
                  ),
                  errorPinTheme: defaultPinTheme.copyBorderWith(
                    border: Border.all(color: Colors.redAccent),
                  ),
                  forceErrorState: controller.errorText.value != null,
                  // Khi bị khoá, dùng dòng đếm ngược riêng bên dưới (live update mỗi giây)
                  // thay vì errorText tĩnh của Pinput để tránh hiển thị số giây bị "đứng hình".
                  errorText: isLocked ? null : controller.errorText.value,
                  errorTextStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  separatorBuilder: (_) => const SizedBox(width: 12),
                  onChanged: (_) => controller.clearError(),
                  onCompleted: (pin) {
                    controller.onCompleted(pin);
                    if (controller.isPINCorrect) {
                      onCompleted?.call();
                    }
                  },
                ),

                if (isLocked) ...[
                  const SizedBox(height: 12),
                  TextWidget(
                    text: "Nhập sai quá nhiều lần. Thử lại sau ${controller.lockRemainingSeconds.value}s",
                    color: Colors.redAccent,
                    size: 13,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            );
          }),
        );
      },
    );
  }

  /// -----------------------
  /// Build Default PIN Theme
  /// -----------------------
  PinTheme _buildDefaultPinTheme() {
    return PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary),
      ),
    );
  }
}
