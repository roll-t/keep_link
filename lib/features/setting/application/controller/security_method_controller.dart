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

  void toggleSecurity() {
    isSecurityEnabled.value = !isSecurityEnabled.value;
    AppGetStorage.setSecurityEnabled(isSecurityEnabled.value);
    if (isSecurityEnabled.value) {
      if (AppGetStorage.getPin() == null) {
        Get.toNamed("/PinVerifyPage");
      }
    } else {
      DialogUtils.show(
        Material(
          color: AppColors.transparent,
          child: Center(child: PinVerifyForm(fromType: FromType.confirm)),
        ),
        binding: PinVerifyBinding(),
      );
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
