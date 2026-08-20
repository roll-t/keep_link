import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/security/application/controller/pin_verify_controller.dart';
import 'package:keep_link/features/security/presentation/widget/pin_verify_form.dart';

class PinVerifyPage extends GetView<PinVerifyController> {
  static const routeName = "/PinVerifyPage";
  const PinVerifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Obx(
          () => TextWidget(
            text: controller.mode.value == FromType.changePassword ? "Change PIN" : "Set PIN",
            textStyle: AppTextStyle.semiBold20,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [PinVerifyForm(fromType: controller.mode.value)],
      ),
    );
  }
}
