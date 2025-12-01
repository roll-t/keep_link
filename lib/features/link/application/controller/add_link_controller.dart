import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class AddLinkController extends GetxController {
  final linkController = TextEditingController();
  final titleController = TextEditingController();

  final RxString errorLinkMess = "".obs;
  final RxString errorTitleMess = "".obs;

  bool validation() {
    bool isValid = true;

    final link = linkController.text.trim();
    final title = titleController.text.trim();

    // Validate link
    if (link.isEmpty) {
      errorLinkMess.value = "Link không được để trống";
      isValid = false;
    } else if (!_isValidUrl(link)) {
      errorLinkMess.value = "Link không hợp lệ";
      isValid = false;
    } else {
      errorLinkMess.value = "";
    }

    // Validate title
    if (title.isEmpty) {
      errorTitleMess.value = "Tiêu đề không được để trống";
      isValid = false;
    } else {
      errorTitleMess.value = "";
    }

    return isValid;
  }

  void onChangeDismissError() {
    if (errorLinkMess.value.isNotEmpty) errorLinkMess.value = "";
    if (errorTitleMess.value.isNotEmpty) errorTitleMess.value = "";
  }

  /// Submit thêm link
  Future<void> addLink() async {
    if (!validation()) return;
    final newLink = linkController.text.trim();
    final newTitle = titleController.text.trim();
    Get.back(result: {"title": newTitle, "link": newLink});
    linkController.clear();
    titleController.clear();
    Fluttertoast.showToast(msg: "Thêm thành công");
  }

  /// Check URL hợp lệ
  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.hasAuthority;
  }

  @override
  void onClose() {
    linkController.dispose();
    titleController.dispose();
    super.onClose();
    super.onClose();
  }
}
