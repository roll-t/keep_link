import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/local_storage/sql_lite.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/core/utils/controller/deep_link_controller.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/core/utils/mixin/argument_handle_mixin_controller.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/presentation/controller/custom_popup_controller.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

class AddLinkController extends GetxController with ArgumentHandlerMixinController<LinkModel> {
  final DeepLinkController _deepLink = Get.find<DeepLinkController>();
  final popup = Get.find<CustomPopupController>();
  final linkController = TextEditingController();
  final titleController = TextEditingController();
  final errorLinkMess = "".obs;
  final errorTitleMess = "".obs;
  final _queryLink = "".obs;
  final isEditModel = false.obs;

  @override
  void onInit() async {
    super.onInit();
    _setupWorkers();
    Future.microtask(_loadInitialData);
  }

  // ===============================================================
  // INIT / WORKERS
  // ===============================================================
  // ===============================================================
  // INIT / WORKERS
  // ===============================================================
  void _setupWorkers() {
    debounce<String>(_queryLink, (link) {
      if (!_isValidUrl(link)) return;

      // === [FIX] ===
      final isOriginalDeepLink = link == _deepLink.deepLink;

      if (isOriginalDeepLink) {
        if (_deepLink.isLoading.value) return; // Bên kia đang fetch rồi
        if (_deepLink.metaData.value?.url == link) return; // Đã có data của link này rồi
      }

      _deepLink.fetchMetaData(link);
    }, time: const Duration(milliseconds: 150));

    ever(_deepLink.metaData, (meta) {
      if (meta != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!isEditModel.value) {
            titleController.text = meta.title;
          }
        });
        if ((meta.title).isNotEmpty) errorTitleMess.value = "";
      }
    });
  }

  void _loadInitialData() {
    isEditModel.value = handleArgumentFromGet();
    if (isEditModel.value && argsData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // select category if exists in popup items (safe)
        final categoryId = argsData?.categoryId ?? "";
        if (categoryId.isEmpty || categoryId == "all") {
          final allItem = popup.items.firstWhereOrNull((e) => e.id == "all");
          popup.selectedItem.value = allItem;
        } else {
          final item = popup.getItemById(categoryId);
          popup.selectedItem.value = item;
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
    if (popup.selectedItem.value?.id == "all" || popup.selectedItem.value?.id == "") {
      DialogUtils.showAlert(
        alertType: AlertType.error,
        title: "Cảnh báo",
        content: "Hãy chọn danh mục",
      );
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
    return popup.selectedItem.value?.id?.trim();
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
        categoryId: popup.selectedItem.value?.id?.trim(),
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
      final extractedUrl = _extractUrl(text!);
      linkController.text = extractedUrl;
      errorLinkMess.value = "";
      if (text != extractedUrl && titleController.text.isEmpty && !isEditModel.value) {
        final remainingText = text.replaceAll(extractedUrl, '').trim();
        titleController.text = remainingText;
      }

      onChangeLink(extractedUrl);
      Fluttertoast.showToast(msg: "Đã dán link");
    } else {
      Fluttertoast.showToast(msg: "Bộ nhớ tạm trống");
    }
  }

  String _extractUrl(String input) {
    // Regex tìm chuỗi bắt đầu bằng http hoặc https và không chứa khoảng trắng
    final RegExp urlRegex = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
    final match = urlRegex.firstMatch(input);
    return match?.group(0) ?? input; // Nếu có link thì trả về link, không thì trả về chuỗi gốc
  }

  // ===============================================================
  // TEXT FIELD CHANGE
  // ===============================================================
  void onChangeLink(String v) {
    if (errorLinkMess.value.isNotEmpty) errorLinkMess.value = "";

    final extractedUrl = _extractUrl(v);
    if (extractedUrl != v && extractedUrl.startsWith(RegExp(r'http'))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Gán lại đúng link vào textfield
        linkController.text = extractedUrl;
        // Đưa con trỏ nhấp nháy về cuối dòng
        linkController.selection = TextSelection.fromPosition(
          TextPosition(offset: extractedUrl.length),
        );

        // Tự gán title
        if (titleController.text.isEmpty && !isEditModel.value) {
          titleController.text = v.replaceAll(extractedUrl, '').trim();
        }
      });
      _queryLink.value = extractedUrl.trim();
      return;
    }

    _queryLink.value = v.trim();
  }

  void onChangeTitle(String v) {
    if (errorTitleMess.value.isNotEmpty) errorTitleMess.value = "";
  }

  // ===============================================================
  // EXIT HANDLER
  // ===============================================================
  void onCancel({dynamic arg}) async {
    if (DeepLinkService.isOpenedFromShare) {
      // final isBubbleEnabled = AppGetStorage.read<bool>('bubble_enabled') ?? false;
      // if (isBubbleEnabled) {
      //   await BubbleService.startBubble();
      // }

      if (Platform.isAndroid) {
        SystemNavigator.pop();
        return;
      }
      // iOS: fallback to back
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
