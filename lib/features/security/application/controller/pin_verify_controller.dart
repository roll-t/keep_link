import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/cache/app_get_storage.dart';
import 'package:keep_link/features/security/presentation/widget/pin_verify_form.dart';

class PinVerifyController extends GetxController {
  // PIN cũ (xác thực)
  final TextEditingController pinController = TextEditingController();

  // PIN mới
  final TextEditingController newPinController = TextEditingController();

  // Xác nhận PIN mới
  final TextEditingController confirmPinController = TextEditingController();
  final Rx<FromType> mode = FromType.create.obs;
  bool isPINCorrect = false;
  final firstPin = "".obs;

  @override
  void onInit() {
    super.onInit();
    final savedPin = AppGetStorage.getPin();

    if (savedPin != null && savedPin.isNotEmpty) {
      if (Get.arguments == FromType.changePassword) {
        mode.value = FromType.changePassword;
      } else {
        mode.value = FromType.confirm;
      }
    } else {
      mode.value = FromType.create;
    }
  }

  @override
  void onClose() {
    pinController.dispose();
    newPinController.dispose();
    confirmPinController.dispose();
    super.onClose();
  }

  // ========================================================
  // XỬ LÝ USER Nhập Đủ 4 số
  // ========================================================
  void onCompleted(String pin) {
    if (mode.value == FromType.create) {
      _handleCreatePin(pin);
    } else {
      _verifyOldPin(pin);
    }
  }

  // Khi nhập PIN mới (đổi PIN)
  void onCompletedNewPin(String pin) {
    firstPin.value = pin;
  }

  // Khi xác nhận PIN mới (đổi PIN)
  void onCompletedConfirmPin(String pin) {
    if (pin != firstPin.value) {
      _toast("PIN confirmation does not match".tr);
      confirmPinController.clear();
      return;
    }

    AppGetStorage.savePin(pin);
    _toast("PIN changed successfully".tr);
    Get.back(result: true);
  }

  // ========================================================
  // XÁC THỰC PIN CŨ
  // ========================================================
  void _verifyOldPin(String pin) {
    final savedPin = AppGetStorage.getPin();
    if (pin != savedPin) {
      _toast("Incorrect PIN".tr);
      _resetAllInput();
      isPINCorrect = false;
      return;
    }

    isPINCorrect = true;
    Get.back(result: true);
  }

  // ========================================================
  // TẠO PIN MỚI (khi tạo lần đầu)
  // ========================================================
  void _handleCreatePin(String pin) {
    // Lần 1
    if (firstPin.value.isEmpty) {
      firstPin.value = pin;
      _toast("Re-enter PIN to confirm".tr);
      pinController.clear();
      return;
    }

    // Lần 2
    if (pin == firstPin.value) {
      AppGetStorage.savePin(pin);

      _toast("PIN has been set".tr);
      Get.back(result: pin);
      return;
    }

    // Không khớp
    _toast("The two PINs do not match".tr);
    firstPin.value = "";
    pinController.clear();
  }

  // Reset toàn bộ input
  void _resetAllInput() {
    pinController.clear();
    newPinController.clear();
    confirmPinController.clear();
  }

  void _toast(String message) => Fluttertoast.showToast(msg: message);
}
