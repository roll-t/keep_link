import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class KeyboardController extends GetxController with WidgetsBindingObserver {
  var isKeyboardOpen = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeMetrics() {
    final views = PlatformDispatcher.instance.views;
    if (views.isNotEmpty) {
      final bottomInset = views.first.viewInsets.bottom;
      isKeyboardOpen.value = bottomInset > 0;
    }
  }
}
