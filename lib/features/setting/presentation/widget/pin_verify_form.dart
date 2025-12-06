import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/setting/application/controller/pin_verify_controller.dart';
import 'package:pinput/pinput.dart';

enum FromType { confirm, create }

class PinVerifyForm extends StatelessWidget {
  const PinVerifyForm({super.key, this.onCompleted, this.fromType = FromType.confirm});

  final VoidCallback? onCompleted;
  final FromType fromType;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PinVerifyController>(
      builder: (controller) {
        final defaultPinTheme = _buildDefaultPinTheme();

        return Container(
          width: Get.width,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.d300, borderRadius: BorderRadius.circular(16)),
          child: Obx(() {
            final isConfirmStep = controller.firstPin.value.isNotEmpty;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextWidget(
                  text: isConfirmStep ? "Xác nhận PIN" : "Nhập PIN",
                  textStyle: AppTextStyle.semiBold20,
                ),
                const SizedBox(height: 20),
                _buildPinput(controller, defaultPinTheme),
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

  /// -----------------------
  /// Build Pinput widget
  /// -----------------------
  Widget _buildPinput(PinVerifyController controller, PinTheme defaultTheme) {
    return Pinput(
      length: 4,
      controller: controller.pinController,
      focusNode: controller.focusNode,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: defaultTheme.copyWith(
        decoration: defaultTheme.decoration!.copyWith(border: Border.all(color: AppColors.primary)),
      ),
      submittedPinTheme: defaultTheme.copyWith(
        decoration: defaultTheme.decoration!.copyWith(
          border: Border.all(color: AppColors.primary),
          color: AppColors.d500,
        ),
      ),
      errorPinTheme: defaultTheme.copyBorderWith(border: Border.all(color: Colors.redAccent)),
      separatorBuilder: (_) => const SizedBox(width: 12),

      onCompleted: (pin) {
        controller.onCompleted(pin, fromType: fromType);
        onCompleted?.call();
      },
    );
  }
}
