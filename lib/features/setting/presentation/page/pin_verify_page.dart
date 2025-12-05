import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/setting/application/controller/pin_verify_controller.dart';
import 'package:pinput/pinput.dart';

class PinVerifyPage extends StatelessWidget {
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
        title: TextWidget(text: "Đặt PIN", textStyle: AppTextStyle.semiBold20),
      ),
      body: PinVerifyForm(),
    );
  }
}

class PinVerifyForm extends StatelessWidget {
  const PinVerifyForm({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PinVerifyController>(
      builder: (controller) {
        final defaultPinTheme = PinTheme(
          width: 56,
          height: 56,
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary),
          ),
        );
        return SizedBox(
          width: Get.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: Get.width,
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.d300,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Obx(() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextWidget(
                        text: controller.firstPin.value.isEmpty ? "Nhập PIN" : "Xác nhận PIN",
                        textStyle: AppTextStyle.semiBold20,
                      ),
                      const SizedBox(height: 20),
                      Pinput(
                        length: 4,
                        controller: controller.pinController,
                        focusNode: controller.focusNode,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            border: Border.all(color: AppColors.primary),
                          ),
                        ),
                        submittedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            border: Border.all(color: AppColors.primary),
                            color: AppColors.d500,
                          ),
                        ),
                        errorPinTheme: defaultPinTheme.copyBorderWith(
                          border: Border.all(color: Colors.redAccent),
                        ),
                        separatorBuilder: (i) => const SizedBox(width: 12),
                        onCompleted: controller.onCompleted,
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
