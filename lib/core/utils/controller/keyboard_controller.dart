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
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    isKeyboardOpen.value = bottomInset > 0;
  }
}
