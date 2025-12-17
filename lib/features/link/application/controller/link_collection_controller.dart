import 'dart:developer';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';
import 'package:keep_link/core/local_storage/sql_lite.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/features/category/application/controller/category_controller.dart';
import 'package:keep_link/features/category/application/controller/custom_popup_controller.dart';
import 'package:keep_link/features/link/data/model/link_model.dart';

class LinkCollectionController extends GetxController {
  final RxList<LinkModel> listLink = <LinkModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  onInit() async {
    super.onInit();
    isLoading.value = true;
    await fetchAllLinks();
    isLoading.value = false;
  }

  Future<void> fetchAllLinks() async {
    final CustomPopupController categoryPopup = DependencyUtils.put(() => CustomPopupController());
    try {
      final selectedCategoryId = categoryPopup.selectedItem.value?.id;
      // ============================================================
      // 1. Check xem có bật bảo mật danh mục không?
      // ============================================================
      final bool isSecurityEnabled = AppGetStorage.isCategorySecurity();
      Set<String?> privateCategoryIds = {};
      // Chỉ đi tìm danh sách Private ID KHI VÀ CHỈ KHI đang bật bảo mật
      if (isSecurityEnabled) {
        if (categoryPopup.items.isNotEmpty) {
          // Lấy từ Controller nếu có sẵn (nhanh nhất)
          privateCategoryIds = categoryPopup.items
              .where((item) => item.visibility == VisibilityStatus.private)
              .map((item) => item.id)
              .toSet();
        } else {
          // Fallback: Lấy từ DB nếu Controller chưa kịp load
          final catRows = await DbHelper.getAll('categories');
          privateCategoryIds = catRows
              .where((row) => row['visibility'] == VisibilityStatus.private.name)
              .map((row) => row['id'] as String?)
              .toSet();
        }
      }
      // ============================================================

      final linkRows = await DbHelper.getAll('links');
      List<LinkModel> links = [];

      if (selectedCategoryId == 'all' || selectedCategoryId == null) {
        links = linkRows
            .where((row) {
              // Nếu tắt bảo mật -> privateCategoryIds rỗng -> !contains luôn là true -> Hiện hết.
              // Nếu bật bảo mật -> privateCategoryIds có dữ liệu -> Ẩn link trùng ID.
              final linkCatId = row['categoryId'];
              return !privateCategoryIds.contains(linkCatId);
            })
            .map((row) => LinkModel.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      } else {
        links = linkRows
            .where((row) => row['categoryId'] == selectedCategoryId)
            .map((row) => LinkModel.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      }

      listLink.assignAll(links);

      log(
        'Fetched ${links.length} links. (Security: $isSecurityEnabled - Filtered IDs: ${privateCategoryIds.length})',
      );
    } catch (e) {
      log('Error fetching links: $e');
    }
  }

  Future<void> onDeleteLink(String id) async {
    try {
      DialogUtils.showConfirm(
        alertType: AlertType.warning,
        title: "Xác nhận",
        content: "Bạn chắc chắn muốn xóa link!",
        onConfirm: () async {
          await DbHelper.delete('links', id);
          listLink.removeWhere((item) => item.id == id);
          Get.back();
          Get.back(); // Đóng dialog confirm
          Fluttertoast.showToast(msg: "Đã xóa");
          log("Deleted link with id: $id");
        },
        onCancel: () {
          Get.back();
        },
      );
    } catch (e) {
      log("Error deleting link: $e");
      Fluttertoast.showToast(msg: "Delete failed");
    }
  }

  void clearLinks() {
    listLink.clear();
  }

  Future<void> onRefreshData() async {
    try {
      await fetchAllLinks();
      if (Get.isRegistered<CategoryController>()) {
        await Get.find<CategoryController>().refreshCategory();
      }
      Fluttertoast.showToast(msg: "Refreshed");
      log('Link data has been refreshed.');
    } catch (e) {
      log('Error refreshing data: $e');
    }
  }
}
