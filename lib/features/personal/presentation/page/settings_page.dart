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
              SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    label: 'Language'.tr,
                    trailing: TextWidget(
                      text: LocalizationService.langs[Get.locale?.languageCode] ?? 'English',
                      color: AppColors.n70,
                      size: 13,
                    ),
                    onTap: () => _showLanguageBottomSheet(context),
                  ),
                  _SettingsTile(
                    icon: Icons.lock_rounded,
                    label: 'Security'.tr,
                    onTap: () =>
                        Get.toNamed(SecurityMethodPage.routeName, arguments: TypePage.create),
                  ),
                ],
              ),

              // ── Support ───────────────────────────────────────────────────
              SizedBox(height: 12),
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
              SizedBox(height: 12),
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

              // ── Sign out ────────────────────────────────────────────────
              Obx(() {
                final currentUser = controller.user.value;
                final loading = controller.isLoading.value;
                final isLoggedIn = currentUser != null;

                if (!isLoggedIn) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : controller.confirmSignOut,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.logout_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                    label: TextWidget(
                      text: loading ? 'Please wait...'.tr : 'Sign Out'.tr,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      size: 15,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
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

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.d500,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextWidget(
                text: 'Select Language'.tr,
                textStyle: AppTextStyle.semiBold20,
                color: AppColors.white,
              ),
              const SizedBox(height: 20),
              ...LocalizationService.langs.entries.map((entry) {
                final langCode = entry.key;
                final langName = entry.value;
                final isSelected = Get.locale?.languageCode == langCode;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () async {
                      await LocalizationService.changeLocale(langCode);
                      Get.back();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? AppColors.primary.withOpacityCompat(0.2)
                            : AppColors.bg700,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: isSelected ? 2 : 0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWidget(
                            text: langName,
                            textStyle: AppTextStyle.semiBold16,
                            color: isSelected ? AppColors.primary : AppColors.white,
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                        ],
                      ),
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
          horizontal: BorderSide(color: AppColors.white.withOpacityCompat(0.06), width: 1),
        ),
      ),
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
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.n70, size: 21),
      title: TextWidget(text: label, color: AppColors.white, size: 14, fontWeight: FontWeight.w500),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded, color: AppColors.n400, size: 20)
              : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minLeadingWidth: 24,
      dense: true,
    );
  }
}
