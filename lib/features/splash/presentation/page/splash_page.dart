import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/splash/presentation/controller/splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  static const String routeName = "/SplashPage";
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: TextWidget(text: "Loading..."));
  }
}
