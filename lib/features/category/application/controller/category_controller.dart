import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/local_storage/sql_lite.dart';
import 'package:keep_link/core/model/item_model.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/features/category/application/controller/custom_popup_controller.dart';
import 'package:keep_link/features/category/data/model/category_model.dart';
import 'package:keep_link/features/link/application/controller/link_collection_controller.dart';

class CategoryController extends GetxController {
  final categoryNameController = TextEditingController();
  final CustomPopupController popupController = DependencyUtils.put(() => CustomPopupController());

  // State
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxString errorMess = "".obs;
  final Rx<VisibilityStatus> visibility = VisibilityStatus.public.obs;

  // Constants
  static const int _maxCategories = 30;

  @override
  void onInit() {
    super.onInit();
    categoryNameController.clear();
    fetchCategories();
  }

  @override
  void onClose() {
    categoryNameController.dispose();
    super.onClose();
  }

  /// -----------------------------
  /// CORE: FETCH & REFRESH (Gộp logic)
  /// -----------------------------
  Future<void> fetchCategories({bool keepSelection = false}) async {
    final res = await DbHelper.getAll(CategoryModel().tableName);
    List<CategoryModel> loadedList = [];
    if (res.isNotEmpty) {
      loadedList = res.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      final defaultCategory = await _createDefaultCategory();
      loadedList.add(defaultCategory);
    }
    _sortCategories(loadedList);
    categories.assignAll(loadedList);

    // Giữ lại ID đang chọn nếu refresh, ngược lại reset
    final currentSelectedId = keepSelection ? popupController.selectedItem.value?.id : null;
    _updatePopupItems(selectId: currentSelectedId);
  }

  Future<CategoryModel> _createDefaultCategory() async {
    final now = DateTime.now();
    final defaultCategory = CategoryModel(
      id: now.millisecondsSinceEpoch.toString(),
      name: "Danh mục",
      createdAt: now,
    );
    await DbHelper.upsert(defaultCategory);
    return defaultCategory;
  }

  /// -----------------------------
  /// CREATE
  /// -----------------------------
  Future<void> addCategory() async {
    if (!_validateCategory()) return;

    try {
      final now = DateTime.now();
      final category = CategoryModel(
        id: now.millisecondsSinceEpoch.toString(),
        name: categoryNameController.text.trim(),
        createdAt: now,
        visibility: visibility.value,
      );

      await DbHelper.upsert(category);

      // Cập nhật UI: Thêm vào đầu danh sách thay vì fetch lại toàn bộ
      categories.insert(0, category);
      _updatePopupItems(selectId: category.id);

      if (!DeepLinkService.isOpenedFromShare) {
        _reloadLinks();
      }
      _closePopup();
    } catch (e, s) {
      _handleError('Add category error', e, s);
    }
  }

  /// -----------------------------
  /// UPDATE
  /// -----------------------------
  Future<void> updateCategory() async {
    if (!_validateCategory()) return;

    final selected = popupController.selectedItem.value;
    if (selected == null || selected.id == 'all') return;

    final index = categories.indexWhere((e) => e.id == selected.id);
    if (index == -1) return;

    final current = categories[index];

    final categoryUpdate = CategoryModel(
      id: current.id,
      name: categoryNameController.text.trim(),
      description: current.description,
      iconUrl: current.iconUrl,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      visibility: visibility.value,
    );

    try {
      await DbHelper.upsert(categoryUpdate);
      Fluttertoast.showToast(msg: "Cập nhật thành công");

      categories[index] = categoryUpdate;
      _sortCategories(categories);
      categories.refresh();

      _updatePopupItems(selectId: categoryUpdate.id);
      _closePopup();
    } catch (e, s) {
      _handleError('Update category error', e, s);
    }
  }

  /// -----------------------------
  /// DELETE
  /// -----------------------------
  Future<void> deleteCategory() async {
    final selected = popupController.selectedItem.value;
    if (selected == null || selected.id == 'all') return;

    if (Get.find<LinkCollectionController>().listLink.isNotEmpty) {
      Fluttertoast.showToast(msg: "Danh mục có chứa link\nKhông thể xóa!");
      return;
    }

    DialogUtils.showConfirm(
      alertType: AlertType.warning,
      title: "Xác nhận",
      content: "Bạn có chắn muốn xóa!",
      onConfirm: () async {
        try {
          final id = selected.id ?? "";
          await DbHelper.delete(CategoryModel().tableName, id);

          categories.removeWhere((e) => e.id == id);
          final newSelectedId = categories.isNotEmpty ? categories.first.id : 'all';
          _updatePopupItems(selectId: newSelectedId);
          _closePopup();
          Get.back(); // Đóng dialog confirm
        } catch (e, s) {
          _handleError('Delete category error', e, s);
        }
      },
      onCancel: () => Get.back(),
    );
  }

  /// -----------------------------
  /// HELPERS & UTILS
  /// -----------------------------

  void _sortCategories(List<CategoryModel> list) {
    list.sort((a, b) {
      final aTime = a.createdAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  void _updatePopupItems({String? selectId}) {
    final newItems = [
      ItemModel(id: "all", name: "Tất cả"),
      ...categories.map((c) => ItemModel(id: c.id, name: c.name, visibility: c.visibility)),
    ];

    popupController.items.assignAll(newItems);

    if (selectId != null) {
      final matched = newItems.firstWhere((e) => e.id == selectId, orElse: () => newItems.first);
      popupController.selectedItem.value = matched;
    } else {
      // Nếu không có selectId, ưu tiên giữ cái cũ nếu nó vẫn tồn tại trong list mới
      // logic cũ của bạn là reset về first, tôi giữ nguyên logic đó.
      popupController.selectedItem.value ??= newItems.first;
    }
  }

  bool _validateCategory() {
    if (categories.length >= _maxCategories) {
      Fluttertoast.showToast(msg: "Tạo được tối đa $_maxCategories danh mục");
      return false;
    }
    if (categoryNameController.text.trim().isEmpty) {
      errorMess.value = "Tên danh mục không được bỏ trống";
      return false;
    }
    errorMess.value = "";
    return true;
  }

  void _handleError(String msg, Object e, StackTrace s) {
    debugPrint('$msg: $e');
    debugPrintStack(stackTrace: s);
    Fluttertoast.showToast(msg: "Có lỗi xảy ra, vui lòng thử lại");
  }

  void _reloadLinks() {
    if (Get.isRegistered<LinkCollectionController>()) {
      Get.find<LinkCollectionController>().refreshData();
    }
  }

  void _closePopup() {
    categoryNameController.clear();
    Get.back();
  }

  // Public methods gọi từ View
  void onChangeDismissError() {
    if (errorMess.value.isNotEmpty) errorMess.value = "";
  }

  Future<void> refreshCategory() async {
    // Tái sử dụng fetchCategories với cờ keepSelection
    await fetchCategories(keepSelection: true);
  }

  Future<void> clearAllCategories() async {
    await DbHelper.clearTable(CategoryModel().tableName);
    categories.clear();
    _updatePopupItems();
  }

  void setVisibility(VisibilityStatus value) => visibility.value = value;

  void onSelectedCategory() {
    visibility.value = popupController.selectedItem.value?.visibility ?? VisibilityStatus.public;
    _reloadLinks();
  }
}
