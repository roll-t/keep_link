import 'package:get/get.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';

class SecurityMethodController extends GetxController {
  final isSecurityEnabled = false.obs;
  final isFingerprintEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    isSecurityEnabled.value = AppGetStorage.isSecurityEnabled();
    isFingerprintEnabled.value = AppGetStorage.isFingerprintEnabled();
  }

  void toggleSecurity() {
    isSecurityEnabled.value = !isSecurityEnabled.value;

    AppGetStorage.setSecurityEnabled(isSecurityEnabled.value);

    if (isSecurityEnabled.value) {
      if (AppGetStorage.getPin() == null) {
        Get.toNamed("/PinVerifyPage");
      }
    }
  }

  void toggleFingerprint() {
    if (!isSecurityEnabled.value) {
      Get.snackbar("Thông báo", "Hãy bật bảo mật trước");
      return;
    }

    isFingerprintEnabled.value = !isFingerprintEnabled.value;
    AppGetStorage.setFingerprintEnabled(isFingerprintEnabled.value);
  }
}
