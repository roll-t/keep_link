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
  final CustomPopupController _popup = Get.find<CustomPopupController>();

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
    debounce<String>(_queryLink, (link) {
      if (_isValidUrl(link)) _deepLink.fetchMetaData(link);
    }, time: const Duration(milliseconds: 200));

    ever(_deepLink.metaData, (meta) {
      if (meta != null) {
        if (!isEditModel.value) {
          titleController.text = meta.title;
        }
        if ((meta.title).isNotEmpty) errorTitleMess.value = "";
      }
    });
  }

  void _loadInitialData() {
    isEditModel.value = handleArgumentFromGet();

    // If editing and argsData contains metadata but deepLink controller has none
    if (isEditModel.value && argsData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // select category if exists in popup items (safe)
        final categoryId = argsData?.categoryId ?? "";
        if (categoryId.isEmpty || categoryId == "all") {
          final allItem = _popup.items.firstWhereOrNull((e) => e.id == "all");
          _popup.selectedItem.value = allItem;
        } else {
          final item = _popup.getItemById(categoryId);
          _popup.selectedItem.value = item;
        }

        // ensure we keep original metadata if deepLink.metaData is empty
        if (_deepLink.metaData.value == null && argsData!.metaDataModel != null) {
          _deepLink.metaData.value = argsData!.metaDataModel;
        }

        // set link & title fallback
        linkController.text = argsData!.metaDataModel?.url.trim() ?? "";
        _queryLink.value = linkController.text;

        if (titleController.text.isEmpty) {
          titleController.text = argsData!.name ?? "";
        }
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
    final selectedId = _selectedCategoryId();
    if (selectedId == null || selectedId.isEmpty || selectedId == 'all') {
      Fluttertoast.showToast(msg: "Hãy chọn danh mục!");
      return false;
    }

    final link = linkController.text.trim();
    final title = titleController.text.trim();

    if (link.isEmpty) return _setError(errorLinkMess, "Link không được để trống");
    if (!_isValidUrl(link)) return _setError(errorLinkMess, "Link không hợp lệ");

    errorLinkMess.value = "";

    if (title.isEmpty) return _setError(errorTitleMess, "Tiêu đề không được để trống");

    errorTitleMess.value = "";
    return true;
  }

  String? _selectedCategoryId() {
    return _popup.selectedItem.value?.id?.trim();
  }

  bool _setError(RxString target, String msg) {
    target.value = msg;
    return false;
  }

  bool _isValidUrl(String url) {
    // Relaxed check: must have scheme (http/https)
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  // ===============================================================
  // ACTION: ADD / UPDATE LINK
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
      final link = LinkModel(
        id: now.millisecondsSinceEpoch.toString(),
        name: titleController.text.trim(),
        metaDataModel: _deepLink.metaData.value ?? argsData?.metaDataModel,
        createdAt: now,
        updatedAt: now,
        categoryId: _selectedCategoryId(),
      );

      await DbHelper.upsert(link);
      Utils.dimissKeyboard();
      _clearAndClose(result: true);

      Fluttertoast.showToast(msg: "Thêm thành công");
    } catch (e, s) {
      log("Error add link => $e\n$s");
      Fluttertoast.showToast(msg: "Thêm thất bại, vui lòng thử lại");
    }
  }

  Future<void> updateLink() async {
    if (!validateInput()) return;

    try {
      final now = DateTime.now();
      final link = LinkModel(
        id: "${argsData?.id}",
        name: titleController.text.trim(),
        metaDataModel: _deepLink.metaData.value ?? argsData?.metaDataModel,
        createdAt: argsData?.createdAt,
        updatedAt: now,
        categoryId: _selectedCategoryId(),
      );

      await DbHelper.update('links', link.id, link.toJson());
      Utils.dimissKeyboard();
      _clearAndClose(result: true);

      Fluttertoast.showToast(msg: "Cập nhật thành công");
    } catch (e, s) {
      log("Error updating link => $e\n$s");
      Fluttertoast.showToast(msg: "Cập nhật thất bại, vui lòng thử lại");
    }
  }

  void _clearAndClose({dynamic result}) {
    _clearInput();
    onCancel(arg: result);
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
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();

    if (text?.isNotEmpty == true) {
      linkController.text = text!;
      errorLinkMess.value = "";
      // trigger the same flow as typing
      onChangeLink(text);
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
        return;
      }
      // iOS: avoid exit(0), fallback to back
      Get.back();
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
