import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/ui/appbar/custom_app_bar.dart';
import 'package:keep_link/features/security/presentation/page/security_method_page.dart';
import 'package:keep_link/features/setting/presentation/page/warning_page.dart';
import 'package:keep_link/features/setting/presentation/widget/item_setting.dart';

class SettingPage extends StatelessWidget {
  static String routeName = "/SettingPage";
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Cài đặt"),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 12).copyWith(top: 16),
        child: Column(
          spacing: 16,
          children: [
            ItemSetting(
              title: "Bảo mật",
              onTap: () {
                Get.toNamed(SecurityMethodPage.routeName, arguments: TypePage.create);
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
            // GetBuilder<BubbleSettingController>(
            //   builder: (controller) {
            //     return Obx(
            //       () => ItemSetting(
            //         title: "Bong bóng tiện ích",
            //         onTap: () async {
            //           await controller.toggleBubble(!controller.isBubbleEnabled.value);
            //         },
            //         leadingIcon: AppVectors.icFloatingExtension.show(
            //           size: 18,
            //           color: AppColors.t300,
            //           backgroundColor: AppColors.d100,
            //           padding: const EdgeInsets.all(8),
            //         ),
            //         subfix: Switch(
            //           value: controller.isBubbleEnabled.value,
            //           onChanged: (value) => controller.toggleBubble(value),
            //         ),
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
