import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/localization/translation_service.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/personal/presentation/controller/personal_controller.dart';
import 'package:keep_link/features/personal/presentation/page/privacy_policy_page.dart';
import 'package:keep_link/features/personal/presentation/page/terms_page.dart';
import 'package:keep_link/features/security/presentation/page/security_method_page.dart';

class SettingsPage extends GetView<PersonalController> {
  static const routeName = '/SettingsPage';

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.bg700,
        appBar: CustomAppBar(
          title: "Settings".tr,
          centerTitle: false,
          titleStyle: AppTextStyle.bold20,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Preferences / General Settings ──────────────────────────
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    label: 'Language'.tr,
                    trailing: TextWidget(
                      text:
                          LocalizationService.langs[Get.locale?.languageCode] ??
                          'English',
                      color: AppColors.n70,
                      size: 13,
                    ),
                    onTap: () => _showLanguageBottomSheet(context),
                  ),
                  _SettingsTile(
                    icon: Icons.lock_rounded,
                    label: 'Security'.tr,
                    onTap: () => Get.toNamed(
                      SecurityMethodPage.routeName,
                      arguments: TypePage.create,
                    ),
                  ),
                ],
              ),

              // ── Support ───────────────────────────────────────────────────
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.star_rounded,
                    label: 'Rate App'.tr,
                    onTap: controller.rateApp,
                  ),
                  _SettingsTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Feedback & Bug Report'.tr,
                    onTap: controller.openFeedbackAndBugReport,
                  ),
                ],
              ),

              // ── About & Legal ─────────────────────────────────────────────
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.privacy_tip_rounded,
                    label: 'Privacy Policy'.tr,
                    onTap: () => Get.toNamed(PrivacyPolicyPage.routeName),
                  ),
                  _SettingsTile(
                    icon: Icons.description_rounded,
                    label: 'Terms of Service'.tr,
                    onTap: () => Get.toNamed(TermsPage.routeName),
                  ),
                  Obx(
                    () => _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: 'App Version'.tr,
                      trailing: TextWidget(
                        text: controller.appVersion.value.isNotEmpty
                            ? controller.appVersion.value
                            : '1.0.0',
                        color: AppColors.n70,
                        size: 13,
                      ),
                      onTap: null,
                    ),
                  ),
                ],
              ),

              // ── Login / Account Section (Screenshot 1) ───────────────────
              const SizedBox(height: 12),
              Obx(() {
                final currentUser = controller.user.value;
                final isLoggedIn = currentUser != null;

                return _SettingsCard(
                  children: [
                    if (isLoggedIn)
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        label: 'Đăng xuất'.tr,
                        trailing: const SizedBox.shrink(),
                        onTap: () => _showSignOutActionSheet(context),
                      )
                    else
                      _SettingsTile(
                        icon: Icons.login_rounded,
                        label: 'Đăng nhập'.tr,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.n400,
                          size: 20,
                        ),
                        onTap: controller.signInWithGoogle,
                      ),
                  ],
                );
              }),

              // ── App Version text at bottom (Screenshot 1) ────────────────
              Padding(
                padding: const EdgeInsets.only(top: 28, bottom: 12),
                child: Center(
                  child: Obx(
                    () => TextWidget(
                      text: controller.appVersion.value.isNotEmpty
                          ? 'v${controller.appVersion.value}'
                          : 'v1.0.0',
                      color: AppColors.n70,
                      size: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.d500,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prompt message (Screenshot 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              child: TextWidget(
                text: 'Bạn có chắc chắn muốn đăng xuất?'.tr,
                color: AppColors.n70,
                size: 13.5,
                fontWeight: FontWeight.w400,
                textAlign: TextAlign.center,
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.white.withOpacityCompat(0.08),
            ),
            // Option: Đăng xuất (Screenshot 2)
            InkWell(
              onTap: () {
                Navigator.of(sheetContext).pop();
                controller.confirmSignOut();
              },
              child: Container(
                height: 52,
                alignment: Alignment.center,
                child: TextWidget(
                  text: 'Đăng xuất'.tr,
                  color: AppColors.danger,
                  size: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(height: 8, color: AppColors.bg700),
            // Option: Hủy (Screenshot 2)
            InkWell(
              onTap: () => Navigator.of(sheetContext).pop(),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                child: TextWidget(
                  text: 'Hủy'.tr,
                  color: AppColors.white,
                  size: 15.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.d500,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: TextWidget(
                        text: 'Language'.tr,
                        color: AppColors.white,
                        size: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...LocalizationService.langs.entries.map((entry) {
                final langCode = entry.key;
                final langName = entry.value;
                final isSelected = Get.locale?.languageCode == langCode;

                return InkWell(
                  onTap: () async {
                    await LocalizationService.changeLocale(langCode);
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextWidget(
                          text: langName,
                          color: AppColors.white,
                          size: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        if (isSelected)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.white,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white.withOpacityCompat(0.25),
                                width: 1.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

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
                  indent: 52,
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.n70, size: 21),
        title: TextWidget(
          text: label,
          color: AppColors.white,
          size: 14,
          fontWeight: FontWeight.w500,
        ),
        trailing:
            trailing ??
            (onTap != null
                ? const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.n400,
                    size: 20,
                  )
                : null),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        minLeadingWidth: 24,
        dense: true,
      ),
    );
  }
}
