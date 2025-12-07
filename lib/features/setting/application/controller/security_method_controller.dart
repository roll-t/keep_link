import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/features/setting/application/di/pin_verify_binding.dart';
import 'package:keep_link/features/setting/presentation/widget/pin_verify_form.dart';

class SecurityMethodController extends GetxController {
  final isSecurityEnabled = false.obs;
  final isFingerprintEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    isSecurityEnabled.value = AppGetStorage.isSecurityEnabled();
    isFingerprintEnabled.value = AppGetStorage.isFingerprintEnabled();
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
          Get.snackbar("Thành công", "Bảo mật đã được bật");
        }
        return;
      }

      // Nếu đã có PIN → chỉ bật
      isSecurityEnabled.value = true;
      AppGetStorage.setSecurityEnabled(true);
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
            },
          ),
        ),
      ),
      binding: PinVerifyBinding(),
    );
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
