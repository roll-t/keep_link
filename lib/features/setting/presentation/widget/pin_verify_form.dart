import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/setting/application/controller/pin_verify_controller.dart';
import 'package:pinput/pinput.dart';

enum FromType { confirm, create, changePassword }

class PinVerifyForm extends StatelessWidget {
  final VoidCallback? onCompleted;
  final FromType fromType;
  final Color? backgound;
  final Widget? title;
  final double? width;
  final EdgeInsets? margin;

  const PinVerifyForm({
    super.key,
    this.onCompleted,
    this.backgound,
    this.fromType = FromType.confirm,
    this.title,
    this.width,
    this.margin,
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
            color: backgound ?? AppColors.d300,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Obx(() {
            final isConfirmStep = controller.firstPin.value.isNotEmpty;
            if (fromType == FromType.changePassword) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(text: "Nhập PIN mới", textStyle: AppTextStyle.semiBold20),
                  const SizedBox(height: 12),

                  // PIN mới
                  Pinput(
                    length: 4,
                    controller: controller.newPinController,
                    focusNode: controller.newPinFocus,
                    defaultPinTheme: defaultPinTheme,
                    onCompleted: (pin) => controller.onCompletedNewPin(pin),
                  ),

                  const SizedBox(height: 24),

                  TextWidget(text: "Xác nhận PIN", textStyle: AppTextStyle.semiBold20),
                  const SizedBox(height: 12),

                  // Xác nhận PIN
                  Pinput(
                    length: 4,
                    controller: controller.confirmPinController,
                    focusNode: controller.confirmPinFocus,
                    defaultPinTheme: defaultPinTheme,
                    onCompleted: (pin) => controller.onCompletedConfirmPin(pin),
                  ),
                ],
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...(title != null
                    ? [title!]
                    : [
                        TextWidget(
                          text: (isConfirmStep ? "Xác nhận PIN" : "Nhập PIN"),
                          textStyle: AppTextStyle.semiBold20,
                        ),
                        SizedBox(height: 20),
                      ]),

                Pinput(
                  length: 4,
                  controller: controller.pinController,
                  focusNode: controller.focusNode,
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
                  separatorBuilder: (_) => const SizedBox(width: 12),
                  onCompleted: (pin) {
                    controller.onCompleted(pin);
                    if (controller.isPINCorrect) {
                      onCompleted?.call();
                    }
                  },
                ),
              ],
            );
          }),
        );
      },
    );
  }

  /// -----------------------
  /// Build Default Pin Theme
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
