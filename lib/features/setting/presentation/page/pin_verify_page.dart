import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/setting/presentation/widget/pin_verify_form.dart';

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
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [PinVerifyForm()]),
    );
  }
}
