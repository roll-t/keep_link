import 'dart:async';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';
import 'package:keep_link/core/service/biometric_service.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';

class SecurityMethodController extends GetxController {
  final isSecurityEnabled = false.obs;
  final isFingerprintEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    isSecurityEnabled.value = AppGetStorage.isSecurityEnabled();
    isFingerprintEnabled.value = AppGetStorage.isFingerprintEnabled();
  }

  // Hàm toast tiện dùng
  void showToast(String message) {
    Fluttertoast.showToast(msg: message);
  }

  void toggleSecurity() async {
    final bool enabled = isSecurityEnabled.value;

    // ================================
    // 1. TRƯỜNG HỢP BẬT BẢO MẬT
    // ================================
    if (!enabled) {
      final savedPin = AppGetStorage.getPin();
      // Nếu chưa có PIN → yêu cầu tạo PIN
      if (savedPin == null) {
        final newPin = await Get.toNamed("/PinVerifyPage");
        if (newPin != null) {
          isSecurityEnabled.value = true;
          AppGetStorage.setSecurityEnabled(true);
          showToast("Bảo mật đã được bật");
        }
        return;
      }
      // Nếu đã có PIN → chỉ bật
      isSecurityEnabled.value = true;
      AppGetStorage.setSecurityEnabled(true);
      showToast("Bảo mật đã được bật");
      return;
    }

    // ================================
    // 2. TRƯỜNG HỢP TẮT BẢO MẬT
    // ================================
    DialogUtils.showPinDialog(
      onCompleted: () async {
        isSecurityEnabled.value = false;
        AppGetStorage.setSecurityEnabled(false);
        showToast("Đã tắt bảo mật");
        if (Get.isDialogOpen ?? false) Get.back();
      },
    );
  }

  Future<bool> verifySecurity() async {
    if (!AppGetStorage.isSecurityEnabled()) return true;
    if (AppGetStorage.isFingerprintEnabled()) {
      final bioSuccess = await BiometricService.authenticate();
      if (bioSuccess) return true;
    }
    final completer = Completer<bool>();

    DialogUtils.showPinDialog(
      onCompleted: () {
        if (Get.isDialogOpen ?? false) Get.back();
        if (!completer.isCompleted) completer.complete(true);
      },
      onDismiss: () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );
    return completer.future;
  }

  void toggleFingerprint() async {
    Fluttertoast.showToast(msg: "Chức năng đang phát triển");
    return;
    // if (!isSecurityEnabled.value) {
    //   showToast("Hãy bật bảo mật trước");
    //   return;
    // }

    // // Kiểm tra thiết bị hỗ trợ
    // if (!await BiometricService.isSupported()) {
    //   showToast("Thiết bị không hỗ trợ vân tay");
    //   return;
    // }

    // // Kiểm tra đã đăng ký vân tay
    // if (!await BiometricService.canCheck()) {
    //   showToast("Bạn chưa đăng ký vân tay trên thiết bị");
    //   return;
    // }

    // // Kiểm tra đã đăng ký vân tay
    // if (!await BiometricService.hasEnrolled()) {
    //   showToast("Bạn chưa đăng ký vân tay trên thiết bị");
    //   return;
    // }

    // // Yêu cầu xác thực trước khi bật/tắt
    // final ok = await BiometricService.authenticate();
    // if (!ok) {
    //   showToast("Xác thực không thành công");
    //   return;
    // }

    // // Toggle
    // isFingerprintEnabled.value = !isFingerprintEnabled.value;
    // AppGetStorage.setFingerprintEnabled(isFingerprintEnabled.value);

    // showToast(
    //   isFingerprintEnabled.value
    //       ? "Đã bật đăng nhập bằng vân tay"
    //       : "Đã tắt đăng nhập bằng vân tay",
    // );
  }
}
