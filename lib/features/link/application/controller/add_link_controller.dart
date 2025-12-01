import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/core/utils/controller/deep_link_controller.dart';

class AddLinkController extends GetxController {
  final TextEditingController linkController = TextEditingController();
  final TextEditingController titleController = TextEditingController();

  final DeepLinkController _deepLinkController = Get.find<DeepLinkController>();

  final RxString errorLinkMess = "".obs;
  final RxString errorTitleMess = "".obs;

  final RxString _queryLink = "".obs;

  @override
  void onInit() {
    super.onInit();

    debounce(_queryLink, (link) {
      if (_isValidUrl(link)) {
        _deepLinkController.fetchMetaData(link);
      }
    }, time: const Duration(milliseconds: 300));

    // Handle Deep Link từ Share
    if (_deepLinkController.deepLink != null && _deepLinkController.deepLink!.isNotEmpty) {
      final sharedLink = _deepLinkController.deepLink!;
      linkController.text = sharedLink;
      if (_isValidUrl(sharedLink)) {
        _deepLinkController.fetchMetaData(sharedLink);
      }
    }

    // Auto-fill Title
    ever(_deepLinkController.metaData, (meta) {
      if (meta != null && titleController.text.isEmpty) {
        titleController.text = meta.title;
      }
    });
  }

  bool validateInput() {
    bool isValid = true;
    final link = linkController.text.trim();
    final title = titleController.text.trim();

    if (link.isEmpty) {
      errorLinkMess.value = "Link không được để trống";
      isValid = false;
    } else if (!_isValidUrl(link)) {
      errorLinkMess.value = "Link không hợp lệ";
      isValid = false;
    } else {
      errorLinkMess.value = "";
    }

    if (title.isEmpty) {
      errorTitleMess.value = "Tiêu đề không được để trống";
      isValid = false;
    } else {
      errorTitleMess.value = "";
    }

    return isValid;
  }

  Future<void> addLink() async {
    if (!validateInput()) return;
    Get.back(result: {"title": titleController.text.trim(), "link": linkController.text.trim()});
    linkController.clear();
    titleController.clear();
    Fluttertoast.showToast(msg: "Thêm thành công");
  }

  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.hasAuthority && (uri.host.isNotEmpty);
  }

  Future<void> onPasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      final pastedText = data.text!;
      linkController.text = pastedText;

      // Clear lỗi ngay
      if (errorLinkMess.value.isNotEmpty) errorLinkMess.value = "";

      // Với Paste, ta gọi fetch NGAY LẬP TỨC (không cần chờ debounce) để trải nghiệm nhanh hơn
      if (_isValidUrl(pastedText)) {
        _deepLinkController.fetchMetaData(pastedText);
      }

      Fluttertoast.showToast(msg: "Đã dán");
    } else {
      Fluttertoast.showToast(msg: "Chưa có dữ liệu trong bộ nhớ tạm");
    }
  }

  // 3. Update hàm này chỉ để đẩy dữ liệu vào luồng debounce
  void onChangLinkTextField(String value) {
    // Clear lỗi UI
    if (errorLinkMess.value.isNotEmpty) errorLinkMess.value = "";

    // Đẩy value vào biến Rx để debounce worker xử lý
    _queryLink.value = value;
  }

  void onChangTitleField(String value) {
    if (errorTitleMess.value.isNotEmpty) errorTitleMess.value = "";
  }

  void onCancel() {
    if (DeepLinkService.isOpenedFromShare) {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else if (Platform.isIOS) {
        exit(0);
      }
    } else {
      Get.back();
    }
  }

  @override
  void onClose() {
    linkController.dispose();
    titleController.dispose();
    // _queryLink tự động dispose theo controller
    super.onClose();
  }
}
