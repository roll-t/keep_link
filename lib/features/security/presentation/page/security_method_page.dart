import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/features/security/application/controller/security_method_controller.dart';
import 'package:keep_link/features/security/presentation/page/pin_verify_page.dart';
import 'package:keep_link/features/security/presentation/widget/pin_verify_form.dart';

class SecurityMethodPage extends GetView<SecurityMethodController> {
  static String routeName = "/SecurityMethodPage";
  const SecurityMethodPage({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: TextWidget(text: "Phương thức bảo mật", textStyle: AppTextStyle.semiBold20),
        ),
        body: SingleChildScrollView(
          child: SizedBox(
            height: (Get.height - 140),
            child: Obx(
              () => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  spacing: 20,
                  children: [
                    // ----- Bật bảo mật -----
                    Container(
                      width: Get.width,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.d300,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWidget(text: "Bật bảo mật", textStyle: AppTextStyle.semiBold20),
                          Switch(
                            value: controller.isSecurityEnabled.value,
                            onChanged: (_) => controller.toggleSecurity(),
                          ),
                        ],
                      ),
                    ),

                    // ----- PIN -----
                    Expanded(
                      child: Opacity(
                        opacity: controller.isSecurityEnabled.value ? 1 : .5,
                        child: IgnorePointer(
                          ignoring: !controller.isSecurityEnabled.value,
                          child: GestureDetector(
                            onTap: () async {
                              DialogUtils.showPinDialog(
                                onCompleted: () async {
                                  DialogUtils.showProgressDialog();
                                  await Future.delayed(Durations.medium2);
                                  Get.back();
                                  await Get.toNamed(
                                    PinVerifyPage.routeName,
                                    arguments: FromType.changePassword,
                                  );
                                },
                              );
                            },
                            child: Container(
                              width: Get.width,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: controller.isSecurityEnabled.value ? 3 : 0,
                                  color: controller.isSecurityEnabled.value
                                      ? AppColors.primary
                                      : AppColors.transparent,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                color: AppColors.d300,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 12,
                                children: [
                                  AppVectors.icPin.show(size: Get.width * .3),
                                  TextWidget(text: "PIN", textStyle: AppTextStyle.bold36),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ----- Vân tay -----
                    Expanded(
                      child: Opacity(
                        opacity: controller.isSecurityEnabled.value ? 1 : .5,
                        child: IgnorePointer(
                          ignoring: !controller.isSecurityEnabled.value,
                          child: GestureDetector(
                            onTap: () => controller.toggleFingerprint(),
                            child: Container(
                              width: Get.width,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: controller.isFingerprintEnabled.value ? 3 : 0,
                                  color: controller.isFingerprintEnabled.value
                                      ? AppColors.primary
                                      : AppColors.transparent,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                color: AppColors.d300,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 12,
                                children: [
                                  AppVectors.icFinger.show(size: Get.width * .3),
                                  TextWidget(text: "Vân tay", textStyle: AppTextStyle.bold36),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
