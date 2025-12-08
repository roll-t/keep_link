import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
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
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: TextWidget(text: "Cài đặt", textStyle: AppTextStyle.semiBold20),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 12).copyWith(top: 16),
        child: Column(
          spacing: 16,
          children: [
            ItemSetting(
              title: "Bảo mật",
              onTap: () {
                Get.toNamed(SecurityMethodPage.routeName);
              },
              leadingIcon: AppVectors.icLock.show(
                size: 18,
                color: AppColors.t300,
                backgroundColor: AppColors.d100,
                padding: EdgeInsets.all(8),
              ),
            ),
            ItemSetting(
              title: "Lưu ý",
              onTap: () {
                Get.toNamed(WarningPage.routeName);
              },
              leadingIcon: AppVectors.icWarning.show(
                size: 18,
                color: AppColors.t300,
                backgroundColor: AppColors.d100,
                padding: EdgeInsets.all(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
