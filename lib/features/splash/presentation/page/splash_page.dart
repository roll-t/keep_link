import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_icons.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/di/dependency_utils.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/security/presentation/widget/pin_verify_form.dart';
import 'package:keep_link/features/splash/presentation/controller/splash_controller.dart';

class SplashPage extends StatefulWidget {
  static const String routeName = '/SplashPage';

  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  Widget build(BuildContext context) {
    final controller = DependencyUtils.find<SplashController>();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: Utils.dimissKeyboard,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _SplashBackground(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(0, constraints.maxHeight - 44),
                      ),
                      child: Center(
                        child: controller == null
                            ? const _SplashContent(
                                needsPin: false,
                                fingerprintEnabled: false,
                              )
                            : GetBuilder<SplashController>(
                                builder: (splashController) {
                                  return _SplashContent(
                                    needsPin:
                                        splashController.needPinVerify.value,
                                    fingerprintEnabled: splashController
                                        .isFingerprintEnabled
                                        .value,
                                    onPinCompleted: splashController.goToHome,
                                    onBiometricPressed:
                                        splashController.verifyFinger,
                                  );
                                },
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashContent extends StatefulWidget {
  final bool needsPin;
  final bool fingerprintEnabled;
  final VoidCallback? onPinCompleted;
  final VoidCallback? onBiometricPressed;

  const _SplashContent({
    required this.needsPin,
    required this.fingerprintEnabled,
    this.onPinCompleted,
    this.onBiometricPressed,
  });

  @override
  State<_SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<_SplashContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<Offset> _logoSlideAnimation;
  late final Animation<double> _pinFadeAnimation;
  late final Animation<Offset> _pinSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();

    // Logo fade-in mượt mà: 0ms -> 320ms
    _logoFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOut),
    );

    // Khi có PIN: Logo trượt mượt mà lên vị trí: 180ms -> 680ms
    _logoSlideAnimation =
        Tween<Offset>(
          begin: widget.needsPin
              ? const Offset(0, 0.28)
              : const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.24, 0.90, curve: Curves.easeOutCubic),
          ),
        );

    // PIN fade-in: 250ms -> 650ms
    _pinFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.33, 0.86, curve: Curves.easeOut),
    );

    // PIN slide theo logo liên tục: 200ms -> 720ms
    _pinSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.42), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.26, 0.96, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    const logoWidth = 175.0;
    final logoHeight = logoWidth * (793 / 1983);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        SlideTransition(
          position: _logoSlideAnimation,
          child: FadeTransition(
            opacity: _logoFadeAnimation,
            child: Container(
              width: logoWidth,
              height: logoHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .13),
                    blurRadius: 36,
                  ),
                ],
              ),
              child: AppIcons.icLogoLinkeepFull.show(fit: BoxFit.contain),
            ),
          ),
        ),

        // Form PIN mở ra đồng thời, khoảng cách 24px cố định
        if (widget.needsPin) ...[
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _pinFadeAnimation,
            child: SlideTransition(
              position: _pinSlideAnimation,
              child: _UnlockCard(
                width: math.min(screenWidth - 48, 320),
                fingerprintEnabled: widget.fingerprintEnabled,
                onPinCompleted: widget.onPinCompleted ?? () {},
                onBiometricPressed: widget.onBiometricPressed ?? () {},
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _UnlockCard extends StatelessWidget {
  final double width;
  final bool fingerprintEnabled;
  final VoidCallback onPinCompleted;
  final VoidCallback onBiometricPressed;

  const _UnlockCard({
    required this.width,
    required this.fingerprintEnabled,
    required this.onPinCompleted,
    required this.onBiometricPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PinVerifyForm(
            width: width - 16,
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            background: AppColors.transparent,
            pinSize: math.max(34, math.min(40, (width - 84) / 4)),
            pinSpacing: 12,
            minimalStyle: true,
            obscureText: true,
            autofocus: false,
            title: const SizedBox.shrink(),
            onCompleted: onPinCompleted,
          ),
          if (fingerprintEnabled) ...[
            const SizedBox(height: 12),
            Text(
              'Or'.tr,
              style: TextStyle(
                color: AppColors.onSurfaceVariant.withValues(alpha: .65),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Semantics(
                button: true,
                label: 'Unlock with biometrics'.tr,
                child: IconButton(
                  onPressed: onBiometricPressed,
                  icon: AppVectors.icFinger.show(
                    size: 32,
                    color: AppColors.primaryFocus,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.gradientTransparent,
                  AppColors.gradientMid,
                  AppColors.gradientStrong,
                ],
                stops: [0, .52, 1],
              ),
            ),
          ),
          Positioned(
            top: -110,
            right: -100,
            child: _GlowOrb(
              size: 300,
              color: AppColors.primary.withValues(alpha: .14),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -120,
            child: _GlowOrb(
              size: 340,
              color: AppColors.ambientPink.withValues(alpha: .09),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
