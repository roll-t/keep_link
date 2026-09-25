import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/security/presentation/controller/pin_verify_controller.dart';
import 'package:pinput/pinput.dart';

enum FromType { confirm, create, changePassword }

class PinVerifyForm extends StatelessWidget {
  final PinVerifyController? controller;
  final VoidCallback? onCompleted;
  final FromType fromType;
  final Color? background;
  final Widget? title;
  final double? width;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final bool isDismissDialog;
  final double pinSize;
  final double pinSpacing;
  final bool minimalStyle;
  final bool obscureText;
  final bool autofocus;

  const PinVerifyForm({
    super.key,
    this.controller,
    this.onCompleted,
    this.background,
    this.fromType = FromType.confirm,
    this.title,
    this.width,
    this.margin,
    this.padding,
    this.isDismissDialog = true,
    this.pinSize = 56,
    this.pinSpacing = 12,
    this.minimalStyle = false,
    this.obscureText = true,
    this.autofocus = true,
  });

  @override
  Widget build(BuildContext context) {
    final pinController = controller ?? Get.find<PinVerifyController>();
    final hasTransparentBackground = background == AppColors.transparent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: width ?? double.infinity,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 24),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background ?? AppColors.navigationSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: hasTransparentBackground
            ? null
            : [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: .34),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .08),
                  blurRadius: 24,
                ),
              ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : (width ?? MediaQuery.sizeOf(context).width - 88);
          final effectiveSpacing = math.min(pinSpacing, 12.0);
          final effectivePinSize = math.max(
            38.0,
            math.min(pinSize, (availableWidth - effectiveSpacing * 3) / 4),
          );
          final themes = _PinThemes(
            size: effectivePinSize,
            minimalStyle: minimalStyle,
          );

          return Obx(() {
            if (fromType == FromType.changePassword) {
              return _buildChangePinForm(
                pinController,
                themes,
                effectiveSpacing,
              );
            }

            return _buildVerifyOrCreateForm(
              pinController,
              themes,
              effectiveSpacing,
            );
          });
        },
      ),
    );
  }

  Widget _buildVerifyOrCreateForm(
    PinVerifyController controller,
    _PinThemes themes,
    double spacing,
  ) {
    final isConfirmStep = controller.firstPin.value.isNotEmpty;
    final isLocked = controller.isLocked;
    final heading = fromType == FromType.create
        ? (isConfirmStep ? 'Xác nhận mã PIN' : 'Tạo mã PIN')
        : 'Nhập mã PIN';
    final helper = fromType == FromType.create
        ? (isConfirmStep
              ? 'Nhập lại mã PIN vừa tạo'
              : 'Dùng 4 chữ số dễ nhớ với bạn')
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          title!
        else ...[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, .12),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(heading),
              children: [
                TextWidget(text: heading, textStyle: AppTextStyle.semiBold16),
                const SizedBox(height: 4),
                if (helper != null)
                  TextWidget(
                    text: helper,
                    textStyle: AppTextStyle.regular12,
                    color: AppColors.onSurfaceVariant,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Semantics(
          label: heading,
          textField: true,
          obscured: obscureText,
          child: Pinput(
            autofocus: autofocus && !isLocked,
            animationDuration: const Duration(milliseconds: 220),
            animationCurve: Curves.easeOutBack,
            pinAnimationType: PinAnimationType.scale,
            keyboardType: TextInputType.number,
            hapticFeedbackType: HapticFeedbackType.lightImpact,
            length: 4,
            controller: controller.pinController,
            focusNode: controller.focusNode,
            enabled: !isLocked,
            obscureText: obscureText,
            obscuringCharacter: '●',
            defaultPinTheme: themes.defaultTheme,
            focusedPinTheme: themes.focusedTheme,
            submittedPinTheme: themes.submittedTheme,
            errorPinTheme: themes.errorTheme,
            forceErrorState: controller.errorText.value != null,
            errorText: isLocked ? null : controller.errorText.value,
            errorTextStyle: const TextStyle(
              color: AppColors.danger,
              fontSize: 13,
            ),
            separatorBuilder: (_) => SizedBox(width: spacing),
            onTapOutside: (_) => Utils.dimissKeyboard(),
            onChanged: (_) => controller.clearError(),
            onCompleted: (pin) {
              if (!controller.onCompleted(pin)) return;
              final callback = onCompleted;
              if (callback != null) {
                callback();
              } else {
                Get.back(result: true);
              }
            },
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLocked
              ? Padding(
                  key: const ValueKey('locked'),
                  padding: const EdgeInsets.only(top: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: TextWidget(
                          text:
                              'Nhập sai quá nhiều lần. Thử lại sau ${controller.lockRemainingSeconds.value}s',
                          color: AppColors.danger,
                          size: 13,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('unlocked')),
        ),
      ],
    );
  }

  Widget _buildChangePinForm(
    PinVerifyController controller,
    _PinThemes themes,
    double spacing,
  ) {
    final hasNewPin = controller.firstPin.value.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.password_rounded, color: AppColors.primary, size: 34),
        const SizedBox(height: 12),
        TextWidget(text: 'Tạo mã PIN mới', textStyle: AppTextStyle.semiBold20),
        const SizedBox(height: 6),
        TextWidget(
          text: hasNewPin
              ? 'Nhập lại mã PIN để xác nhận'
              : 'Mã PIN gồm 4 chữ số',
          size: 13,
          color: AppColors.onSurfaceVariant,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        Pinput(
          autofocus: autofocus,
          animationDuration: const Duration(milliseconds: 220),
          animationCurve: Curves.easeOutBack,
          pinAnimationType: PinAnimationType.scale,
          keyboardType: TextInputType.number,
          hapticFeedbackType: HapticFeedbackType.lightImpact,
          length: 4,
          obscureText: true,
          obscuringCharacter: '●',
          controller: controller.newPinController,
          focusNode: controller.newPinFocus,
          defaultPinTheme: themes.defaultTheme,
          focusedPinTheme: themes.focusedTheme,
          submittedPinTheme: themes.submittedTheme,
          separatorBuilder: (_) => SizedBox(width: spacing),
          onTapOutside: (_) => Utils.dimissKeyboard(),
          onChanged: (_) => controller.clearError(),
          onCompleted: controller.onCompletedNewPin,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: hasNewPin
              ? Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Pinput(
                    autofocus: false,
                    animationDuration: const Duration(milliseconds: 220),
                    animationCurve: Curves.easeOutBack,
                    pinAnimationType: PinAnimationType.scale,
                    keyboardType: TextInputType.number,
                    hapticFeedbackType: HapticFeedbackType.lightImpact,
                    length: 4,
                    obscureText: true,
                    obscuringCharacter: '●',
                    controller: controller.confirmPinController,
                    focusNode: controller.confirmPinFocus,
                    defaultPinTheme: themes.defaultTheme,
                    focusedPinTheme: themes.focusedTheme,
                    submittedPinTheme: themes.submittedTheme,
                    errorPinTheme: themes.errorTheme,
                    forceErrorState: controller.errorText.value != null,
                    errorText: controller.errorText.value,
                    errorTextStyle: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                    ),
                    separatorBuilder: (_) => SizedBox(width: spacing),
                    onTapOutside: (_) => Utils.dimissKeyboard(),
                    onChanged: (_) => controller.clearError(),
                    onCompleted: controller.onCompletedConfirmPin,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _PinThemes {
  final double size;
  final bool minimalStyle;

  const _PinThemes({required this.size, required this.minimalStyle});

  PinTheme get defaultTheme => PinTheme(
    width: size,
    height: size,
    textStyle: TextStyle(
      color: AppColors.onSurface,
      fontSize: minimalStyle ? 20 : 22,
      fontWeight: FontWeight.w600,
    ),
    decoration: minimalStyle
        ? _minimalDecoration(AppColors.primaryContainer.withValues(alpha: .24))
        : BoxDecoration(
            color: AppColors.background.withValues(alpha: .42),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryContainer.withValues(alpha: .14),
            ),
          ),
  );

  PinTheme get focusedTheme => defaultTheme.copyWith(
    decoration: minimalStyle
        ? _minimalDecoration(AppColors.primaryDim, width: 2)
        : BoxDecoration(
            color: AppColors.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryDim, width: 1.5),
          ),
  );

  PinTheme get submittedTheme => defaultTheme.copyWith(
    decoration: minimalStyle
        ? _minimalDecoration(AppColors.primary.withValues(alpha: .72))
        : BoxDecoration(
            color: AppColors.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: .7)),
          ),
  );

  PinTheme get errorTheme => defaultTheme.copyWith(
    decoration: minimalStyle
        ? _minimalDecoration(AppColors.danger, width: 2)
        : BoxDecoration(
            color: AppColors.danger.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.danger),
          ),
  );

  BoxDecoration _minimalDecoration(Color color, {double width = 1.5}) {
    return BoxDecoration(
      border: Border(
        bottom: BorderSide(color: color, width: width),
      ),
    );
  }
}
