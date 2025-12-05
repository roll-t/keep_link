import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_images.dart';
import 'package:keep_link/features/splash/presentation/controller/splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  static const String routeName = "/SplashPage";
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: AppImages.iLogo.show(size: Get.width * .35)),
    );
  }
}
