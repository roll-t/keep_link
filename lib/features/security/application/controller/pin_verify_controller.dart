import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';
import 'package:keep_link/features/security/presentation/widget/pin_verify_form.dart';

class PinVerifyController extends GetxController {
  // PIN cũ (xác thực)
  final TextEditingController pinController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  // PIN mới
  final TextEditingController newPinController = TextEditingController();
  final FocusNode newPinFocus = FocusNode();

  // Xác nhận PIN mới
  final TextEditingController confirmPinController = TextEditingController();
  final FocusNode confirmPinFocus = FocusNode();
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
    focusNode.dispose();

    newPinController.dispose();
    newPinFocus.dispose();

    confirmPinController.dispose();
    confirmPinFocus.dispose();
    super.onClose();
  }

  // ========================================================
  // XỬ LÝ USER Nhập Đủ 4 số
  // ========================================================
  void onCompleted(String pin) {
    switch (mode.value) {
      case FromType.create:
        _handleCreatePin(pin);
        break;

      case FromType.confirm:
        _verifyOldPin(pin);
        break;

      case FromType.changePassword:
        _verifyOldPin(pin);
        break;
    }
  }

  // Khi nhập PIN mới (đổi PIN)
  void onCompletedNewPin(String pin) {
    firstPin.value = pin;
  }

  // Khi xác nhận PIN mới (đổi PIN)
  void onCompletedConfirmPin(String pin) {
    if (pin != firstPin.value) {
      _toast("PIN xác nhận không khớp");
      confirmPinController.clear();
      confirmPinFocus.requestFocus();
      return;
    }

    AppGetStorage.savePin(pin);
    _toast("Đổi PIN thành công");
    Get.back(result: true);
  }

  // ========================================================
  // XÁC THỰC PIN CŨ
  // ========================================================
  void _verifyOldPin(String pin) {
    final savedPin = AppGetStorage.getPin();
    if (pin != savedPin) {
      _toast("PIN không đúng");
      _resetAllInput();
      isPINCorrect = false;
      return;
    }

    // Nếu đang đổi PIN → qua bước nhập PIN mới
    if (mode.value == FromType.changePassword) {
      mode.value = FromType.create; // Sang bước tạo PIN mới
      firstPin.value = "";
      _resetAllInput();
      _toast("Nhập PIN mới");
      return;
    }

    // Dùng cho xác thực mở khóa
    _toast("PIN chính xác");
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
      _toast("Nhập lại PIN để xác nhận");
      pinController.clear();
      return;
    }

    // Lần 2
    if (pin == firstPin.value) {
      AppGetStorage.savePin(pin);

      _toast("PIN đã được thiết lập");
      Get.back(result: pin);
      return;
    }

    // Không khớp
    _toast("Hai lần nhập không khớp");
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
