import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
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

  // Lỗi hiển thị ngay trên khung PIN (viền đỏ + text), thay vì chỉ toast thoáng qua
  final RxnString errorText = RxnString();

  // Số giây còn lại bị khoá do nhập sai quá nhiều lần (0 = không bị khoá)
  final RxInt lockRemainingSeconds = 0.obs;
  Timer? _lockTicker;

  bool get isLocked => lockRemainingSeconds.value > 0;

  @override
  void onInit() {
    super.onInit();
    if (AppGetStorage.hasPin()) {
      if (Get.arguments == FromType.changePassword) {
        mode.value = FromType.changePassword;
      } else {
        mode.value = FromType.confirm;
      }
    } else {
      mode.value = FromType.create;
    }
    _refreshLockState();
  }

  @override
  void onClose() {
    _lockTicker?.cancel();
    pinController.dispose();
    focusNode.dispose();

    newPinController.dispose();
    newPinFocus.dispose();

    confirmPinController.dispose();
    confirmPinFocus.dispose();
    super.onClose();
  }

  void clearError() => errorText.value = null;

  void _refreshLockState() {
    _lockTicker?.cancel();
    final remaining = AppGetStorage.pinLockRemaining()?.inSeconds ?? 0;
    lockRemainingSeconds.value = remaining;
    if (remaining <= 0) return;

    _lockTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = AppGetStorage.pinLockRemaining()?.inSeconds ?? 0;
      lockRemainingSeconds.value = left;
      if (left <= 0) {
        _lockTicker?.cancel();
        errorText.value = null;
      }
    });
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (confirmPinFocus.canRequestFocus) confirmPinFocus.requestFocus();
      });
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
    if (isLocked) {
      isPINCorrect = false;
      // clear() trước vì nó tự kích hoạt onChanged -> clearError(); set message SAU để không bị ghi đè về null.
      _resetAllInput();
      errorText.value = "Đã khoá tạm thời, thử lại sau ${lockRemainingSeconds.value}s";
      return;
    }

    if (!AppGetStorage.verifyPin(pin)) {
      AppGetStorage.registerPinFailure();
      _refreshLockState();
      isPINCorrect = false;
      _resetAllInput();

      if (isLocked) {
        errorText.value = "Sai PIN nhiều lần. Đã khoá ${lockRemainingSeconds.value}s";
      } else {
        errorText.value = "PIN không đúng";
      }
      _toast(errorText.value!);
      return;
    }

    errorText.value = null;
    AppGetStorage.resetPinFailCount();

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

      errorText.value = null;
      _toast("PIN đã được thiết lập");
      Get.back(result: pin);
      return;
    }

    // Không khớp
    firstPin.value = "";
    // clear() trước vì nó tự kích hoạt onChanged -> clearError(); set message SAU để không bị ghi đè về null.
    pinController.clear();
    errorText.value = "Hai lần nhập không khớp";
    _toast(errorText.value!);
  }

  // Reset toàn bộ input
  void _resetAllInput() {
    pinController.clear();
    newPinController.clear();
    confirmPinController.clear();
  }

  void _toast(String message) => Fluttertoast.showToast(msg: message);
}
