import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/data/models/item_model.dart';
import 'package:keep_link/core/data/repositories/link_repository.dart';
import 'package:keep_link/core/services/platform/deep_link_service.dart';
import 'package:keep_link/core/state/controllers/deep_link_controller.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/core/state/mixins/argument_handle_mixin_controller.dart';
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
  final linkText = "".obs;
  final titleText = "".obs;
  final isEditModel = false.obs;
  final isSaving = false.obs;

  // `popup` is the SAME global CustomPopupController the main collection
  // header uses to filter its list. Picking a category here is only meant to
  // choose where THIS link is saved — it must not permanently change what
  // category the collection screen is browsing underneath. Remember it here
  // and put it back on the way out (see onClose).
  ItemModel? _previousSelection;

  // True once the user has actually typed into the title field (as opposed
  // to it being auto-filled by our own code). Guards the metadata listener
  // below from overwriting a title the user is in the middle of typing.
  bool _titleEditedByUser = false;

  @override
  void onInit() async {
    super.onInit();
    _previousSelection = popup.selectedItem.value;
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
      if (meta == null) return;
      if (meta.title.isNotEmpty) errorTitleMess.value = "";

      // Đừng tự điền tiêu đề nếu: đang sửa link có sẵn, user đã tự gõ gì đó
      // rồi (kể cả khi đang gõ dở, fetch xong lúc đó không được ghi đè), hoặc
      // fetch fail/rỗng (title="" thì giữ nguyên tiêu đề đang có thay vì xoá
      // trắng nó đi — trước đây dòng này luôn set title = "" khi fetch lỗi,
      // xoá mất cả tiêu đề user vừa gõ hoặc phần text đoán được từ clipboard).
      if (isEditModel.value) return;
      if (_titleEditedByUser) return;
      if (meta.title.isEmpty) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_titleEditedByUser) return; // user có thể đã gõ trong lúc chờ frame này
        titleController.text = meta.title;
        titleText.value = meta.title;
      });
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
        // KHÔNG set _queryLink ở đây — nó sẽ kích hoạt debounce fetch lại
        // metadata từ mạng dù URL không đổi. Ta đã có sẵn metadata gốc
        // (dòng phía trên), và nếu fetch lại chẳng may lỗi/timeout thì
        // preview + title sẽ bị thay bằng dữ liệu rỗng dù dữ liệu cũ vẫn
        // còn tốt. Chỉ fetch lại khi user thực sự sửa URL (qua onChangeLink).
        linkText.value = linkController.text;

        if (titleController.text.isEmpty) {
          titleController.text = argsData!.name ?? "";
          titleText.value = titleController.text;
        }
      });
    }

    // OPEN FROM SHARE
    final sharedLink = _deepLink.deepLink;
    if (sharedLink != null && sharedLink.isNotEmpty) {
      linkController.text = sharedLink;
      linkText.value = sharedLink;
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
    if (isSaving.value) return; // chặn bấm Lưu nhiều lần tạo trùng link
    if (isEditModel.value) {
      updateLink();
    } else {
      addLink();
    }
  }

  Future<void> addLink() async {
    if (!validateInput()) return;
    isSaving.value = true;
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
      await LinkRepository.insert(link);
      Utils.dimissKeyboard();
      _clearAndClose(result: true);
      Fluttertoast.showToast(msg: "Added successfully".tr);
    } catch (e, s) {
      log("Error add link => $e\n$s");
      Fluttertoast.showToast(msg: "Failed to add, please try again".tr);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> updateLink() async {
    if (!validateInput()) return;
    isSaving.value = true;
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

      await LinkRepository.update(link);
      Utils.dimissKeyboard();
      _clearAndClose(result: true);

      Fluttertoast.showToast(msg: "Updated successfully".tr);
    } catch (e, s) {
      log("Error updating link => $e\n$s");
      Fluttertoast.showToast(msg: "Failed to update, please try again".tr);
    } finally {
      isSaving.value = false;
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
    linkText.value = "";
    titleText.value = "";
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
        titleText.value = remainingText;
      }

      onChangeLink(extractedUrl);
      Fluttertoast.showToast(msg: "Link pasted".tr);
    } else {
      Fluttertoast.showToast(msg: "Clipboard is empty".tr);
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
    linkText.value = v;

    final extractedUrl = _extractUrl(v);
    if (extractedUrl != v && extractedUrl.startsWith(RegExp(r'http'))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Gán lại đúng link vào textfield
        linkController.text = extractedUrl;
        linkText.value = extractedUrl;
        // Đưa con trỏ nhấp nháy về cuối dòng
        linkController.selection = TextSelection.fromPosition(
          TextPosition(offset: extractedUrl.length),
        );

        // Tự gán title
        if (titleController.text.isEmpty && !isEditModel.value) {
          titleController.text = v.replaceAll(extractedUrl, '').trim();
          titleText.value = titleController.text;
        }
      });
      _queryLink.value = extractedUrl.trim();
      return;
    }

    _queryLink.value = v.trim();
  }

  void onChangeTitle(String v) {
    _titleEditedByUser = true;
    titleText.value = v;
    if (errorTitleMess.value.isNotEmpty) errorTitleMess.value = "";
  }

  // ===============================================================
  // EXIT HANDLER
  // ===============================================================
  void onCancel({dynamic arg}) async {
    // Khôi phục lại category đang browse ở màn danh sách chính TRƯỚC KHI
    // Get.back() trả kết quả — nếu không, .then((success) => refreshData())
    // ở màn danh sách sẽ refresh nhầm sang category vừa chọn cho link này.
    // (onClose() bên dưới cũng gọi lại hàm này — phòng trường hợp user thoát
    // bằng nút back hệ thống thay vì nút Huỷ/Lưu, không đi qua onCancel().)
    _restorePreviousSelection();

    if (DeepLinkService.isOpenedFromShare) {
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

  void _restorePreviousSelection() {
    popup.selectedItem.value = _previousSelection;
  }

  @override
  void onClose() {
    // Safety net: guarantees the restore happens no matter how this page was
    // left (Huỷ/Lưu already call onCancel(), but the Android system back
    // button pops the route directly and skips it entirely).
    _restorePreviousSelection();
    linkController.dispose();
    titleController.dispose();
    super.onClose();
  }
}
