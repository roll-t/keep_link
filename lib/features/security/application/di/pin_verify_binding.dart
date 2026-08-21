import 'package:get/get.dart';
import 'package:keep_link/features/security/application/controller/pin_verify_controller.dart';

class PinVerifyBinding extends Bindings {
  @override
  void dependencies() {
    // PinVerifyController is reused for very different flows (verify-to-unlock,
    // create PIN, change PIN) from multiple entry points (splash lock screen,
    // security-settings PIN dialog, the dedicated PinVerifyPage). It must never
    // be left over from a previous screen: stale `mode`/`firstPin` state or
    // leftover digits in the Pinput controllers would silently corrupt the next
    // flow (e.g. "Change PIN" completing instantly without asking for a new PIN).
    // Always force a brand new instance so onInit() re-evaluates state fresh.
    if (Get.isRegistered<PinVerifyController>()) {
      Get.delete<PinVerifyController>(force: true);
    }
    Get.put(PinVerifyController());
  }
}
