import 'package:get/get.dart';
import 'package:keep_link/features/security/application/controller/pin_verify_controller.dart';

class PinVerifyBinding extends Bindings {
  @override
  void dependencies() {
    // Force delete stale instance so a fresh controller is always created.
    // Without this, the dialog's controller (which may be mid-disposal) would
    // be reused by PinVerifyPage, causing "TextEditingController used after
    // being disposed" crashes.
    if (Get.isRegistered<PinVerifyController>()) {
      Get.delete<PinVerifyController>(force: true);
    }
    Get.lazyPut<PinVerifyController>(() => PinVerifyController());
  }
}
