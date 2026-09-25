import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_icons.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/services/platform/biometric_service.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/security/presentation/controller/pin_verify_controller.dart';
import 'package:keep_link/features/security/presentation/widget/pin_verify_form.dart';

/// Màn hình khóa khi ứng dụng quay lại foreground.
class AppLockPage extends StatefulWidget {
  const AppLockPage({super.key});

  @override
  State<AppLockPage> createState() => _AppLockPageState();
}

class _AppLockPageState extends State<AppLockPage>
    with SingleTickerProviderStateMixin {
  late final String _pinControllerTag;
  late final PinVerifyController _pinController;
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _fingerprintEnabled = false;
  bool _biometricInFlight = false;

  @override
  void initState() {
    super.initState();
    _pinControllerTag = 'app_lock_${DateTime.now().microsecondsSinceEpoch}';
    _pinController = Get.put(
      PinVerifyController(initialMode: FromType.confirm),
      tag: _pinControllerTag,
      permanent: true,
    );
    _fingerprintEnabled = AppGetStorage.isFingerprintEnabled();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: .97, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    if (_fingerprintEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    final tag = _pinControllerTag;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<PinVerifyController>(tag: tag)) {
        Get.delete<PinVerifyController>(tag: tag, force: true);
      }
    });
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    if (_biometricInFlight || !mounted) return;
    setState(() => _biometricInFlight = true);
    try {
      if (!await BiometricService.canCheck()) {
        if (mounted) Utils.showToast('Biometrics is currently unavailable'.tr);
        return;
      }
      final ok = await BiometricService.authenticate();
      if (ok && mounted) Get.back(result: true);
    } finally {
      if (mounted) setState(() => _biometricInFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = math.min(screenWidth - 48, 320.0);
    const logoWidth = 175.0;
    final logoHeight = logoWidth * (793 / 1983);

    return PopScope(
      canPop: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: Utils.dimissKeyboard,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.background,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const _LockBackground(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 48,
                        ),
                        child: Center(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: SizedBox(
                                width: cardWidth,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: logoWidth,
                                      height: logoHeight,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(
                                              alpha: .13,
                                            ),
                                            blurRadius: 36,
                                          ),
                                        ],
                                      ),
                                      child: AppIcons.icLogoLinkeepFull.show(
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Welcome back'.tr,
                                      style: const TextStyle(
                                        color: AppColors.onSurface,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Authenticate to continue using Linkeep'
                                          .tr,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    PinVerifyForm(
                                      controller: _pinController,
                                      width: cardWidth - 16,
                                      margin: EdgeInsets.zero,
                                      padding: EdgeInsets.zero,
                                      background: AppColors.transparent,
                                      pinSize: math.max(
                                        34,
                                        math.min(40, (cardWidth - 84) / 4),
                                      ),
                                      pinSpacing: 12,
                                      minimalStyle: true,
                                      obscureText: true,
                                      autofocus: false,
                                      title: const SizedBox.shrink(),
                                      onCompleted: () {
                                        if (mounted) Get.back(result: true);
                                      },
                                    ),
                                    if (_fingerprintEnabled) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        'Or'.tr,
                                        style: TextStyle(
                                          color: AppColors.onSurfaceVariant
                                              .withValues(alpha: .65),
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Semantics(
                                          button: true,
                                          label: 'Unlock with biometrics'.tr,
                                          child: IconButton(
                                            onPressed: _biometricInFlight
                                                ? null
                                                : _tryBiometric,
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
                              ),
                            ),
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
      ),
    );
  }
}

class _LockBackground extends StatelessWidget {
  const _LockBackground();

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
            child: _Glow(
              size: 300,
              color: AppColors.primary.withValues(alpha: .14),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -120,
            child: _Glow(
              size: 340,
              color: AppColors.ambientPink.withValues(alpha: .09),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

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
