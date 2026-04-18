import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/core/lang/theme.dart';
import 'package:keep_link/core/lang/translation_service.dart';
import 'package:keep_link/core/service/theme_service.dart';
import 'package:keep_link/core/ui/appbar/custom_app_bar.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/security/presentation/page/security_method_page.dart';
import 'package:keep_link/features/setting/presentation/page/warning_page.dart';
import 'package:keep_link/features/setting/presentation/widget/item_setting.dart';

class SettingPage extends StatelessWidget {
  static String routeName = "/SettingPage";
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Settings".tr),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 12).copyWith(top: 16),
        child: Column(
          spacing: 16,
          children: [
            ItemSetting(
              title: "Security".tr,
              onTap: () {
                Get.toNamed(SecurityMethodPage.routeName, arguments: TypePage.create);
              },
              leadingIcon: AppVectors.icLock.show(
                size: 18,
                color: AppColors.onSurfaceVariant,
                backgroundColor: AppColors.surfaceContainerLow,
                padding: EdgeInsets.all(8),
              ),
            ),
            ItemSetting(
              title: "Warnings".tr,
              onTap: () {
                Get.toNamed(WarningPage.routeName);
              },
              leadingIcon: AppVectors.icWarning.show(
                size: 18,
                color: AppColors.onSurfaceVariant,
                backgroundColor: AppColors.surfaceContainerLow,
                padding: EdgeInsets.all(8),
              ),
            ),
            // Language Selector
            ItemSetting(
              title: "Language".tr,
              leadingIcon: AppVectors.iclang.show(
                size: 18,
                color: AppColors.onSurfaceVariant,
                backgroundColor: AppColors.surfaceContainerLow,
                padding: EdgeInsets.all(8),
              ),
              onTap: () => _showLanguageBottomSheet(context),
            ),
            // Theme Selector
            // ItemSetting(
            //   title: "Theme".tr,
            //   leadingIcon: AppVectors.icSetting.show(
            //     size: 18,
            //     color: AppColors.onSurfaceVariant,
            //     backgroundColor: AppColors.surfaceContainerLow,
            //     padding: EdgeInsets.all(8),
            //   ),
            //   onTap: () => _showThemeBottomSheet(context),
            // ),
          ],
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
      backgroundColor: AppColors.surfaceContainerHighest,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextWidget(
                text: "Select Language".tr,
                textStyle: AppTextStyle.semiBold20,
                color: AppColors.onSurface,
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
                            : AppColors.surfaceContainerLow,
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
                            color: isSelected ? AppColors.primary : AppColors.onSurface,
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, color: AppColors.primary),
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

  void _showThemeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.surfaceContainerHighest,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextWidget(
                text: "Select Theme".tr,
                textStyle: AppTextStyle.semiBold20,
                color: AppColors.onSurface,
              ),
              const SizedBox(height: 20),
              ...ThemeService.availableThemes.map((theme) {
                final themeName = theme.displayName;
                final isSelected = ThemeService.themeMode == theme;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () async {
                      await ThemeService.changeTheme(theme);
                      Get.back();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? AppColors.primary.withOpacityCompat(0.2)
                            : AppColors.surfaceContainerLow,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: isSelected ? 2 : 0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWidget(
                            text: themeName.tr,
                            textStyle: AppTextStyle.semiBold16,
                            color: isSelected ? AppColors.primary : AppColors.onSurface,
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, color: AppColors.primary),
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
