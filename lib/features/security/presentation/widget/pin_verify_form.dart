import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/security/application/controller/pin_verify_controller.dart';
import 'package:pinput/pinput.dart';

enum FromType { confirm, create, changePassword }

class PinVerifyForm extends StatefulWidget {
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
  State<PinVerifyForm> createState() => _PinVerifyFormState();
}

class _PinVerifyFormState extends State<PinVerifyForm> {
  // FocusNodes live with the widget — disposed when widget unmounts,
  // not when the GetX controller is deleted.
  final FocusNode _focusNode = FocusNode();
  final FocusNode _newPinFocus = FocusNode();
  final FocusNode _confirmPinFocus = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    _newPinFocus.dispose();
    _confirmPinFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PinVerifyController>(
      builder: (controller) {
        final defaultPinTheme = _buildDefaultPinTheme();
        return Container(
          width: widget.width ?? Get.width,
          margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.background ?? AppColors.d300,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Obx(() {
            final isConfirmStep = controller.firstPin.value.isNotEmpty;
            if (widget.fromType == FromType.changePassword) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextWidget(text: "Enter New PIN", textStyle: AppTextStyle.semiBold20),
                  const SizedBox(height: 12),

                  // PIN mới
                  Pinput(
                    autofocus: true,
                    onTapOutside: (event) {
                      Utils.dimissKeyboard();
                    },
                    length: 4,
                    controller: controller.newPinController,
                    focusNode: _newPinFocus,
                    defaultPinTheme: defaultPinTheme,
                    onCompleted: (pin) {
                      controller.onCompletedNewPin(pin);
                      _confirmPinFocus.requestFocus();
                    },
                  ),

                  const SizedBox(height: 28),

                  TextWidget(text: "Confirm PIN", textStyle: AppTextStyle.semiBold20),
                  const SizedBox(height: 12),

                  // Xác nhận PIN
                  Pinput(
                    length: 4,
                    controller: controller.confirmPinController,
                    focusNode: _confirmPinFocus,
                    defaultPinTheme: defaultPinTheme,
                    onCompleted: (pin) => controller.onCompletedConfirmPin(pin),
                  ),
                ],
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...(widget.title != null
                    ? [widget.title!]
                    : [
                        TextWidget(
                          text: (isConfirmStep ? "Confirm PIN" : "Enter PIN"),
                          textStyle: AppTextStyle.semiBold20,
                        ),
                        SizedBox(height: 20),
                      ]),

                Pinput(
                  autofocus: true,
                  length: 4,
                  controller: controller.pinController,
                  focusNode: _focusNode,
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
                      widget.onCompleted?.call();
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
