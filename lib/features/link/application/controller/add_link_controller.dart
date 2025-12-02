import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/local_storage/sql_lite.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/core/ui/popup/custom_popup_controller.dart';
import 'package:keep_link/core/utils/controller/deep_link_controller.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/link/data/model/link_model.dart';

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
    _setupWorkers();
    _checkInitialData();
  }

  void _setupWorkers() {
    debounce(_queryLink, (link) {
      if (_isValidUrl(link)) {
        _deepLinkController.fetchMetaData(link);
      }
    }, time: const Duration(milliseconds: 200));
    ever(_deepLinkController.metaData, (meta) {
      if (meta != null) {
        titleController.text = meta.title;
        if (titleController.text.isNotEmpty) {
          errorTitleMess.value = "";
        }
      }
    });
  }

  void _checkInitialData() {
    final sharedLink = _deepLinkController.deepLink;
    if (sharedLink != null && sharedLink.isNotEmpty) {
      linkController.text = sharedLink;
      onChangLinkTextField(sharedLink);
    }
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
    try {
      if (!validateInput()) return;
      final now = DateTime.now();
      final link = LinkModel(
        id: now.millisecondsSinceEpoch.toString(),
        name: titleController.text.trim(),
        metaDataModel: _deepLinkController.metaData.value,
        createdAt: now,
        updatedAt: now,
        categoryId: Get.find<CustomPopupController>().selectedItem.value?.id?.trim(),
      );
      await DbHelper.upsert(link);
      Utils.dimissKeyboard();
      onCancel();
      _clearInputs();

      Fluttertoast.showToast(msg: "Thêm thành công");
    } catch (e, stackTrace) {
      log("Error adding link: $e");
      print(stackTrace);
      Fluttertoast.showToast(msg: "Thêm thất bại, vui lòng thử lại");
    }
  }

  void _clearInputs() {
    linkController.clear();
    titleController.clear();
    _queryLink.value = "";
  }

  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasScheme &&
        ['http', 'https'].contains(uri.scheme) &&
        uri.hasAuthority;
  }

  Future<void> onPasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pastedText = data?.text;
    if (pastedText != null && pastedText.isNotEmpty) {
      linkController.text = pastedText;
      errorLinkMess.value = "";
      _queryLink.value = pastedText;
      Fluttertoast.showToast(msg: "Đã dán link");
    } else {
      Fluttertoast.showToast(msg: "Bộ nhớ tạm trống");
    }
  }

  void onChangLinkTextField(String value) {
    if (errorLinkMess.value.isNotEmpty) errorLinkMess.value = "";
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
        try {
          exit(0);
        } catch (e) {
          Get.back();
        }
      }
    } else {
      Get.back();
    }
  }

  @override
  void onClose() {
    linkController.dispose();
    titleController.dispose();
    super.onClose();
  }
}
