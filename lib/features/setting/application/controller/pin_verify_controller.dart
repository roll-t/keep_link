import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';
import 'package:keep_link/features/setting/presentation/widget/pin_verify_form.dart';

class PinVerifyController extends GetxController {
  late final TextEditingController pinController;
  late final FocusNode focusNode;
  final formKey = GlobalKey<FormState>();
  final mode = "create".obs;
  final firstPin = "".obs;

  @override
  void onInit() {
    super.onInit();
    pinController = TextEditingController();
    focusNode = FocusNode();
    mode.value = Get.arguments?['mode'] ?? "create";
  }

  @override
  void onClose() {
    pinController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  // ========================================================
  //  KHI USER NHẬP ĐỦ 6 SỐ — XỬ LÝ THEO MODE
  // ========================================================
  void onCompleted(String pin, {FromType? fromType}) {
    if (fromType == FromType.confirm) {
      _verifyOldPin(pin);
      return;
    }

    if (mode.value == "confirm") {
      _verifyOldPin(pin);
    } else {
      _createNewPin(pin);
    }
  }

  // ========================================================
  //  DÙNG CHO TRƯỜNG HỢP BẬT/TẮT BẢO MẬT
  // ========================================================

  void verifyToggleSecurity() {
    final savedPin = AppGetStorage.getPin();
    if (savedPin == null || savedPin.isEmpty) {
      mode.value = "create";
      Fluttertoast.showToast(msg: "Chưa có PIN. Vui lòng tạo PIN mới");
      return;
    }
    mode.value = "confirm";
    Fluttertoast.showToast(msg: "Nhập PIN để tắt bảo mật");
  }

  // ========================================================
  //  XÁC THỰC PIN CŨ
  // ========================================================
  void _verifyOldPin(String pin) {
    final savedPin = AppGetStorage.getPin();
    if (savedPin == pin) {
      Fluttertoast.showToast(msg: "Đã tắt bảo mật");
      Get.back(result: true);
    } else {
      Fluttertoast.showToast(msg: "PIN không đúng");
      pinController.clear();
    }
  }

  // ========================================================
  //  TẠO PIN MỚI (nhập 2 lần)
  // ========================================================
  void _createNewPin(String pin) {
    if (firstPin.value.isEmpty) {
      firstPin.value = pin;
      pinController.clear();
      Fluttertoast.showToast(msg: "Nhập lại PIN để xác nhận");
      return;
    }

    if (firstPin.value == pin) {
      AppGetStorage.savePin(pin);
      Fluttertoast.showToast(msg: "PIN đã được thiết lập");
      Get.back(result: pin);
    } else {
      Fluttertoast.showToast(msg: "Hai lần nhập không khớp");
      firstPin.value = "";
      pinController.clear();
    }
  }
}
