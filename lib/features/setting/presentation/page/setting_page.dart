import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/setting/presentation/page/security_method_page.dart';

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
          children: [
            GestureDetector(
              onTap: () {
                Get.toNamed(SecurityMethodPage.routeName);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.d300,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextWidget(
                      text: "Bảo mật",
                      color: AppColors.t300,
                      textStyle: AppTextStyle.semiBold18,
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: AppColors.t300),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
