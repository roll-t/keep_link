import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/core/utils/controller/deep_link_controller.dart';
import 'package:keep_link/features/category/application/controller/custom_popup_controller.dart';
import 'package:keep_link/features/link/application/controller/add_link_controller.dart';

class NativeBridge {
  static const MethodChannel _bubble = MethodChannel('keep_link/bubble_click');
  static bool _isProcessing = false;

  static void init() {
    _bubble.setMethodCallHandler(_handleBubbleClick);
  }

  static Future<dynamic> _handleBubbleClick(MethodCall call) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      DependencyUtils.put(() => CustomPopupController());
      DependencyUtils.put(() => DeepLinkController());
      DependencyUtils.put(() => AddLinkController());

      final addLinkController = Get.isRegistered<AddLinkController>()
          ? Get.find<AddLinkController>()
          : null;
      if (addLinkController != null) {
        print(">>> AddLinkController has created!");
        addLinkController.onNativeClick();
      } else {
        print(">>> Fail can't create AddLinkController");
      }
    } catch (e, s) {
      print("NativeBridge Error: $e\n$s");
    } finally {
      await Future.delayed(const Duration(milliseconds: 200));
      _isProcessing = false;
    }
  }
}
