import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';

class PinVerifyController extends GetxController {
  late final TextEditingController pinController;
  late final FocusNode focusNode;

  final formKey = GlobalKey<FormState>();

  // Lưu 4 số đầu để xác nhận lại
  final firstPin = "".obs;

  @override
  void onInit() {
    super.onInit();
    pinController = TextEditingController();
    focusNode = FocusNode();
  }

  @override
  void onClose() {
    pinController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  void onCompleted(String pin) {
    // Lần đầu nhập
    if (firstPin.value.isEmpty) {
      firstPin.value = pin;
      pinController.clear();
    }
    // Xác nhận lại
    if (firstPin.value == pin) {
      AppGetStorage.savePin(pin);
      Fluttertoast.showToast(msg: "Thành công\nPIN đã được thiết lập");
      Get.back(result: pin);
    } else {
      Fluttertoast.showToast(msg: "Sai PIN\n2 PIN không trùng khớp");
      firstPin.value = "";
      pinController.clear();
    }
  }
}
