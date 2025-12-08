import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';
import 'package:keep_link/core/service/biometric_service.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/features/security/application/di/pin_verify_binding.dart';
import 'package:keep_link/features/security/presentation/widget/pin_verify_form.dart';

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
    DialogUtils.show(
      Material(
        color: AppColors.transparent,
        child: Center(
          child: PinVerifyForm(
            onCompleted: () async {
              isSecurityEnabled.value = false;
              AppGetStorage.setSecurityEnabled(false);
              showToast("Đã tắt bảo mật");
            },
          ),
        ),
      ),
      binding: PinVerifyBinding(),
    );
  }

  void toggleFingerprint() async {
    if (!isSecurityEnabled.value) {
      showToast("Hãy bật bảo mật trước");
      return;
    }

    // Kiểm tra thiết bị hỗ trợ
    if (!await BiometricService.isSupported()) {
      showToast("Thiết bị không hỗ trợ vân tay");
      return;
    }

    // Kiểm tra đã đăng ký vân tay
    if (!await BiometricService.canCheck()) {
      showToast("Bạn chưa đăng ký vân tay trên thiết bị");
      return;
    }

    // Kiểm tra đã đăng ký vân tay
    if (!await BiometricService.hasEnrolled()) {
      showToast("Bạn chưa đăng ký vân tay trên thiết bị");
      return;
    }

    // Yêu cầu xác thực trước khi bật/tắt
    final ok = await BiometricService.authenticate();
    if (!ok) {
      showToast("Xác thực không thành công");
      return;
    }

    // Toggle
    isFingerprintEnabled.value = !isFingerprintEnabled.value;
    AppGetStorage.setFingerprintEnabled(isFingerprintEnabled.value);

    showToast(
      isFingerprintEnabled.value
          ? "Đã bật đăng nhập bằng vân tay"
          : "Đã tắt đăng nhập bằng vân tay",
    );
  }
}
