import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/local_storage/sql_lite.dart';
import 'package:keep_link/core/model/item_model.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/features/category/application/controller/custom_popup_controller.dart';
import 'package:keep_link/features/category/data/model/category_model.dart';
import 'package:keep_link/features/link/application/controller/link_collection_controller.dart';

class CategoryController extends GetxController {
  final categoryNameController = TextEditingController();
  final CustomPopupController popupController = Get.put(CustomPopupController());
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxString errorMess = "".obs;

  @override
  void onInit() {
    super.onInit();
    categoryNameController.clear();
    fetchCategories();
  }

  /// -----------------------------
  /// CREATE / INSERT
  /// -----------------------------
  Future<void> addCategory() async {
    if (!_validateCategoryName()) return;

    final now = DateTime.now();
    final category = CategoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: categoryNameController.text.trim(),
      createdAt: now,
    );
    await DbHelper.upsert(category);
    categories.add(category);
    _updatePopupItems(selectId: category.id);
    if (!DeepLinkService.isOpenedFromShare) {
      Get.find<LinkCollectionController>().fetchAllLinks();
    }
    _closePopup();
  }

  /// -----------------------------
  /// READ / GET ALL
  /// -----------------------------
  Future<void> fetchCategories() async {
    final res = await DbHelper.getAll(CategoryModel().tableName);
    if (res.isNotEmpty) {
      categories.value = res
          .map(
            (e) => CategoryModel(
              id: e['id'],
              name: e['name'],
              description: e['description'],
              iconUrl: e['icon_url'],
              createdAt: e['created_at'] != null ? DateTime.tryParse(e['created_at']) : null,
              updatedAt: e['updated_at'] != null ? DateTime.tryParse(e['updated_at']) : null,
            ),
          )
          .toList();

      categories.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });

      _updatePopupItems();
    }
  }

  /// -----------------------------
  /// UPDATE
  /// -----------------------------
  Future<void> updateCategory() async {
    if (!_validateCategoryName()) return;
    final selected = popupController.selectedItem.value;
    if (selected == null || selected.id == 'all') return;
    final current = categories.firstWhere((e) => e.id == selected.id);
    final categoryUpdate = CategoryModel(
      id: selected.id,
      name: categoryNameController.text,
      createdAt: current.createdAt,
    );
    await DbHelper.upsert(categoryUpdate);
    final index = categories.indexWhere((e) => e.id == categoryUpdate.id);
    if (index != -1) categories[index] = categoryUpdate;
    _updatePopupItems(selectId: categoryUpdate.id);
    _closePopup();
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
        final id = selected.id ?? "";
        await DbHelper.delete(CategoryModel().tableName, id);
        categories.removeWhere((e) => e.id == id);
        final newSelectedId = categories.isNotEmpty ? categories.first.id : 'all';
        _updatePopupItems(selectId: newSelectedId);
        _closePopup();

        Get.back();
      },
      onCancel: () {
        Get.back();
      },
    );
  }

  /// -----------------------------
  /// CLEAR TABLE
  /// -----------------------------
  Future<void> clearAllCategories() async {
    await DbHelper.clearTable(CategoryModel().tableName);
    categories.clear();
    _updatePopupItems();
  }

  void onChangeDismissError() {
    if (errorMess.trim().isEmpty) return;
    errorMess.value = "";
  }

  /// -----------------------------
  /// VALIDATION
  /// -----------------------------
  bool _validateCategoryName() {
    final name = categoryNameController.text.trim();
    if (name.isEmpty) {
      errorMess.value = "Tên danh mục không được bỏ trống";
      return false;
    }
    errorMess.value = "";
    return true;
  }

  /// -----------------------------
  /// CẬP NHẬT DỮ LIỆU CHO POPUP
  /// -----------------------------
  void _updatePopupItems({String? selectId}) {
    // Tạo danh sách items (thêm Tất cả ở đầu)
    final newItems = [
      ItemModel(id: "all", name: "Tất cả"),
      ...categories.map((c) => ItemModel(id: c.id, name: c.name)),
    ];

    // Gán vào popupController
    popupController.items
      ..clear()
      ..addAll(newItems);

    // Xử lý chọn item
    if (selectId != null) {
      // Tìm item, nếu không có thì chọn "Tất cả"
      final matched = newItems.firstWhere((e) => e.id == selectId, orElse: () => newItems.first);
      popupController.selectedItem.value = matched;
    } else {
      // Nếu chưa có selected -> lấy item đầu tiên
      popupController.selectedItem.value ??= newItems.first;
    }

    popupController.items.refresh();
  }

  /// -----------------------------
  /// ĐÓNG POPUP
  /// -----------------------------
  void _closePopup() {
    categoryNameController.clear();
    Get.back();
  }
}
