import 'package:get/get.dart';
import 'package:keep_link/features/security/presentation/controller/pin_verify_controller.dart';

class PinVerifyBinding extends Bindings {
  @override
  void dependencies() {
    // Không force-delete controller mà một route đang render. Dialog và màn
    // app-lock dùng controller có tag riêng để các luồng không ghi đè nhau.
    if (!Get.isRegistered<PinVerifyController>()) {
      Get.put(PinVerifyController());
    }
  }
}
