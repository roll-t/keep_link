import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_images.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/features/setting/presentation/widget/pin_verify_form.dart';
import 'package:keep_link/features/splash/presentation/controller/splash_controller.dart';

class SplashPage extends StatelessWidget {
  static const String routeName = "/SplashPage";
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    // LẤY CONTROLLER MỘT CÁCH AN TOÀN
    final controller = DependencyUtils.find<SplashController>();

    return Scaffold(
      body: Center(
        child: Obx(() {
          final RxBool securityEnabled = controller?.isSecurityEnabled ?? false.obs;

          return Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 20,
            children: [
              AppImages.iLogo.show(size: Get.width * .35),

              // Nếu cần nhập PIN thì hiện form
              if (securityEnabled.value)
                PinVerifyForm(
                  onCompleted: () {
                    controller?.goToHome();
                  },
                ),
            ],
          );
        }),
      ),
    );
  }
}
