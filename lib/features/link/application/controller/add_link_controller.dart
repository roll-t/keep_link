import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/local_storage/sql_lite.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/core/utils/controller/deep_link_controller.dart';
import 'package:keep_link/core/utils/mixin/argument_handle_mixin_controller.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/application/controller/custom_popup_controller.dart';
import 'package:keep_link/features/link/data/model/link_model.dart';

class AddLinkController extends GetxController with ArgumentHandlerMixinController<LinkModel> {
  final DeepLinkController _deepLink = Get.find<DeepLinkController>();

  final linkController = TextEditingController();
  final titleController = TextEditingController();
  final errorLinkMess = "".obs;
  final errorTitleMess = "".obs;
  final _queryLink = "".obs;
  final isEditModel = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setupWorkers();
    Future.microtask(_loadInitialData);
  }

  // ===============================================================
  // INIT / WORKERS
  // ===============================================================

  void _setupWorkers() {
    debounce(_queryLink, (link) {
      if (_isValidUrl(link)) _deepLink.fetchMetaData(link);
    }, time: const Duration(milliseconds: 200));
    ever(_deepLink.metaData, (meta) {
      if (meta != null) {
        if (!isEditModel.value) {
          titleController.text = meta.title;
        }
        if (meta.title.isNotEmpty) errorTitleMess.value = "";
      }
    });
  }

  void _loadInitialData() {
    isEditModel.value = handleArgumentFromGet();
    final popup = Get.find<CustomPopupController>();

    if (isEditModel.value && argsData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categoryId = argsData?.categoryId ?? "";

        if (categoryId.isEmpty || categoryId == "all") {
          final allItem = popup.items.firstWhereOrNull((e) => e.id == "all");
          popup.selectedItem.value = allItem;
        } else {
          final item = popup.getItemById(categoryId);
          popup.selectedItem.value = item;
        }

        // ---- Set link, title ----
        linkController.text = argsData!.metaDataModel?.url.trim() ?? "";
        _queryLink.value = linkController.text;
        titleController.text = argsData!.name ?? "";
      });
    }

    // OPEN FROM SHARE
    final sharedLink = _deepLink.deepLink;
    if (sharedLink != null && sharedLink.isNotEmpty) {
      linkController.text = sharedLink;
      onChangeLink(sharedLink);
    }
  }

  // ===============================================================
  // VALIDATION
  // ===============================================================

  bool validateInput() {
    final link = linkController.text.trim();
    final title = titleController.text.trim();
    if (link.isEmpty) return _setError(errorLinkMess, "Link không được để trống");
    if (!_isValidUrl(link)) return _setError(errorLinkMess, "Link không hợp lệ");
    errorLinkMess.value = "";
    if (title.isEmpty) return _setError(errorTitleMess, "Tiêu đề không được để trống");
    errorTitleMess.value = "";
    return true;
  }

  bool _setError(RxString target, String msg) {
    target.value = msg;
    return false;
  }

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasScheme &&
        ['http', 'https'].contains(uri.scheme) &&
        uri.hasAuthority;
  }

  // ===============================================================
  // ACTION: ADD LINK
  // ===============================================================

  void onSave() {
    if (isEditModel.value) {
      updateLink();
    } else {
      addLink();
    }
  }

  Future<void> addLink() async {
    if (!validateInput()) return;
    try {
      final now = DateTime.now();
      final popup = Get.find<CustomPopupController>();
      final link = LinkModel(
        id: now.millisecondsSinceEpoch.toString(),
        name: titleController.text.trim(),
        metaDataModel: _deepLink.metaData.value,
        createdAt: now,
        updatedAt: now,
        categoryId: popup.selectedItem.value?.id?.trim(),
      );
      await DbHelper.upsert(link);
      Utils.dimissKeyboard();
      onCancel(arg: true);
      _clearInput();

      Fluttertoast.showToast(msg: "Thêm thành công");
    } catch (e, s) {
      log("Error add link => $e\n$s");
      Fluttertoast.showToast(msg: "Thêm thất bại, vui lòng thử lại");
    }
  }

  Future<void> updateLink() async {
    try {
      if (!validateInput()) return;
      final now = DateTime.now();
      final link = LinkModel(
        id: "${argsData?.id}",
        name: titleController.text.trim(),
        metaDataModel: _deepLink.metaData.value,
        createdAt: argsData?.createdAt,
        updatedAt: now,
        categoryId: Get.find<CustomPopupController>().selectedItem.value?.id?.trim(),
      );
      await DbHelper.update('links', link.id, link.toJson());
      Utils.dimissKeyboard();
      onCancel(arg: true);
      _clearInput();
      Fluttertoast.showToast(msg: "Cập nhật thành công");
    } catch (e, s) {
      log("Error updating link => $e\n$s");
      Fluttertoast.showToast(msg: "Cập nhật thất bại, vui lòng thử lại");
    }
  }

  void _clearInput() {
    linkController.clear();
    titleController.clear();
    _queryLink.value = "";
  }

  // ===============================================================
  // CLIPBOARD
  // ===============================================================

  Future<void> onPasteClipboard() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;

    if (text != null && text.trim().isNotEmpty) {
      linkController.text = text.trim();
      errorLinkMess.value = "";
      _queryLink.value = text.trim();
      Fluttertoast.showToast(msg: "Đã dán link");
    } else {
      Fluttertoast.showToast(msg: "Bộ nhớ tạm trống");
    }
  }

  // ===============================================================
  // TEXT FIELD CHANGE
  // ===============================================================

  void onChangeLink(String v) {
    if (errorLinkMess.value.isNotEmpty) errorLinkMess.value = "";
    _queryLink.value = v.trim();
  }

  void onChangeTitle(String v) {
    if (errorTitleMess.value.isNotEmpty) errorTitleMess.value = "";
  }

  // ===============================================================
  // EXIT HANDLER
  // ===============================================================

  void onCancel({dynamic arg}) {
    if (DeepLinkService.isOpenedFromShare) {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else {
        try {
          exit(0);
        } catch (_) {
          Get.back();
        }
      }
    } else {
      Get.back(result: arg);
    }
  }

  @override
  void onClose() {
    linkController.dispose();
    titleController.dispose();
    super.onClose();
  }
}
