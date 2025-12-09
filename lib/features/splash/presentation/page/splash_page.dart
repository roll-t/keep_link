import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_images.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/security/presentation/widget/pin_verify_form.dart';
import 'package:keep_link/features/splash/presentation/controller/splash_controller.dart';

class SplashPage extends StatelessWidget {
  static const String routeName = "/SplashPage";
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DependencyUtils.find<SplashController>();
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(AppImages.iBgSplash.path), fit: BoxFit.cover),
      ),
      child: GestureDetector(
        onTap: () {
          Utils.dimissKeyboard();
        },
        child: Scaffold(
          backgroundColor: AppColors.transparent,
          body: Center(
            child: Obx(() {
              final RxBool needPinVerify = controller?.needPinVerify ?? false.obs;
              return Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 28,
                children: [
                  AppImages.iLogo.show(size: Get.width * .35),
                  if (needPinVerify.value)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.d700,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      width: Get.width * .8,
                      padding: EdgeInsets.only(bottom: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PinVerifyForm(
                            width: Get.width * .8,
                            margin: EdgeInsets.zero,
                            background: AppColors.d700,
                            onCompleted: () {
                              controller?.goToHome();
                            },
                          ),
                          if (controller?.isFingerprintEnabled.value ?? false) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: TextWidget(text: "Hoặc"),
                            ),
                            AppVectors.icFinger.show(
                              size: 60,
                              onTap: () {
                                controller?.verifyFinger();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
