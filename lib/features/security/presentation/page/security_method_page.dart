import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:keep_link/core/presentation/widgets/text/list_title_widget.dart';
import 'package:keep_link/core/presentation/widgets/text/text_extension.dart';
import 'package:keep_link/features/security/presentation/controller/security_method_controller.dart';

class SecurityMethodPage extends GetView<SecurityMethodController> {
  static const String routeName = '/SecurityMethodPage';

  const SecurityMethodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Bảo mật', centerTitle: false),
      body: Obx(() {
        if (!controller.isVerified.value) {
          return const Center(
            child: SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }

        final appLockEnabled = controller.isAppSecurityEnabled.value;
        final categoryLockEnabled = controller.isCategorySecurityEnabled.value;
        final backgroundLockEnabled = controller.isBackgroundLockEnabled.value;
        final biometricEnabled = controller.isFingerprintEnabled.value;
        final hasActivePin =
            appLockEnabled || categoryLockEnabled || backgroundLockEnabled;
        final isBusy = controller.isBusy.value;

        return Stack(
          children: [
            AbsorbPointer(
              absorbing: isBusy,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  top: 12,
                  bottom: 24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  _SecuritySummary(
                    appLockEnabled: appLockEnabled,
                    categoryLockEnabled: categoryLockEnabled,
                    backgroundLockEnabled: backgroundLockEnabled,
                    biometricEnabled: biometricEnabled,
                  ),
                  const _SectionHeader(title: 'Lớp bảo vệ'),
                  _SecuritySectionCard(
                    children: [
                      ListTitleWidget(
                        icon: Icons.phonelink_lock_rounded,
                        title: 'Khóa ứng dụng',
                        subtitle: 'Yêu cầu mã PIN khi mở',
                        isActive: appLockEnabled,
                        onTap: controller.toggleAppSecurity,
                        trailing: _SmallSwitch(
                          value: appLockEnabled,
                          onChanged: (_) => controller.toggleAppSecurity(),
                        ),
                      ),
                      ListTitleWidget(
                        icon: Icons.folder_special_outlined,
                        title: 'Khóa danh mục riêng tư',
                        subtitle: 'Bảo vệ danh mục riêng tư',
                        isActive: categoryLockEnabled,
                        onTap: controller.toggleCategorySecurity,
                        trailing: _SmallSwitch(
                          value: categoryLockEnabled,
                          onChanged: (_) => controller.toggleCategorySecurity(),
                        ),
                      ),
                      ListTitleWidget(
                        icon: Icons.screen_lock_portrait_rounded,
                        title: 'Khóa khi quay lại ứng dụng',
                        subtitle: 'Xác thực khi mở lại từ nền',
                        isActive: backgroundLockEnabled,
                        onTap: controller.toggleBackgroundLock,
                        trailing: _SmallSwitch(
                          value: backgroundLockEnabled,
                          onChanged: (_) => controller.toggleBackgroundLock(),
                        ),
                      ),
                    ],
                  ),
                  const _SectionHeader(title: 'Phương thức xác thực'),
                  _SecuritySectionCard(
                    children: [
                      ListTitleWidget(
                        icon: Icons.password_rounded,
                        title: 'Mã PIN',
                        subtitle: hasActivePin
                            ? 'Đổi mã PIN 4 chữ số'
                            : 'Bật bảo vệ để cài mã PIN',
                        isActive: hasActivePin,
                        isEnabled: hasActivePin,
                        onTap: controller.changePin,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatusPill(
                              text: hasActivePin ? 'Đã thiết lập' : 'Chưa bật',
                              isActive: hasActivePin,
                            ),
                            if (hasActivePin) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.n400,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                      ),
                      ListTitleWidget(
                        icon: Icons.fingerprint_rounded,
                        title: 'Sinh trắc học',
                        subtitle: (appLockEnabled || backgroundLockEnabled)
                            ? 'Dùng vân tay hoặc khuôn mặt'
                            : 'Bật khóa ứng dụng trước',
                        isActive: biometricEnabled,
                        isEnabled: appLockEnabled || backgroundLockEnabled,
                        onTap: controller.toggleFingerprint,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatusPill(
                              text: biometricEnabled ? 'Đang dùng' : 'Đang tắt',
                              isActive: biometricEnabled,
                            ),
                            if (appLockEnabled || backgroundLockEnabled) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.n400,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const _PrivacyNote(),
                ],
              ),
            ),
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: isBusy ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                child: Container(
                  color: AppColors.background.withOpacityCompat(.28),
                  alignment: Alignment.center,
                  child: const SizedBox.square(
                    dimension: 30,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _SecuritySummary extends StatelessWidget {
  final bool appLockEnabled;
  final bool categoryLockEnabled;
  final bool backgroundLockEnabled;
  final bool biometricEnabled;

  const _SecuritySummary({
    required this.appLockEnabled,
    required this.categoryLockEnabled,
    required this.backgroundLockEnabled,
    required this.biometricEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final protectionCount = [
      appLockEnabled,
      categoryLockEnabled,
      backgroundLockEnabled,
    ].where((value) => value).length;
    final isProtected = protectionCount > 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.d500,
        border: Border.symmetric(
          horizontal: BorderSide(
            color: AppColors.white.withOpacityCompat(0.06),
            width: 1,
          ),
        ),
      ),
      child: ListTitleWidget(
        icon: isProtected ? Icons.shield_rounded : Icons.shield_outlined,
        title: isProtected ? 'Đang được bảo vệ' : 'Chưa bật bảo vệ',
        subtitle: isProtected
            ? '$protectionCount lớp bảo vệ${biometricEnabled ? ' • Sinh trắc học' : ''}'
            : 'Bật bảo vệ để bắt đầu',
        isActive: isProtected,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: title.textSemiBold12(),
    );
  }
}

class _SecuritySectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SecuritySectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.d500,
        border: Border.symmetric(
          horizontal: BorderSide(
            color: AppColors.white.withOpacityCompat(0.06),
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: AppColors.transparent,
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 60,
                  endIndent: 0,
                  color: AppColors.white.withOpacityCompat(0.08),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SmallSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SmallSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.72,
      alignment: Alignment.centerRight,
      child: Switch.adaptive(
        value: value,
        activeTrackColor: AppColors.primary,
        activeThumbColor: AppColors.primaryContainer,
        inactiveThumbColor: AppColors.n400,
        inactiveTrackColor: AppColors.white.withOpacityCompat(0.12),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onChanged: (val) {
          HapticFeedback.selectionClick();
          onChanged(val);
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final bool isActive;

  const _StatusPill({required this.text, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withOpacityCompat(0.16)
            : AppColors.white.withOpacityCompat(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: text.textSemiBold10(
        color: isActive
            ? AppColors.primaryContainer
            : AppColors.onSurfaceVariant,
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: AppColors.n400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: 'Mã PIN được mã hóa an toàn trên thiết bị.'.textRegular10(
              color: AppColors.n400,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
