import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';
import 'package:keep_link/core/local_storage/sql_lite.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/features/category/application/controller/category_controller.dart';
import 'package:keep_link/features/category/application/controller/custom_popup_controller.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

class LinkCollectionController extends GetxController {
  // --- State Variables ---
  final RxList<LinkModel> listLink = <LinkModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadMore = false.obs;

  // --- Pagination Variables ---
  final ScrollController scrollController = ScrollController();
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _canLoadMore = true;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_scrollListener);
    refreshData();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  // Lắng nghe sự kiện cuộn để load thêm dữ liệu
  void _scrollListener() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (!isLoading.value && !isLoadMore.value && _canLoadMore) {
        loadMore();
      }
    }
  }

  /// Reset toàn bộ dữ liệu (Gọi khi đổi Category hoặc Kéo để làm mới)
  Future<void> refreshData({bool showToast = false}) async {
    _currentPage = 0;
    _canLoadMore = true;
    listLink.clear();
    await fetchAllLinks(isInitial: true);

    if (showToast) {
      Fluttertoast.showToast(msg: "Đã làm mới");
    }
  }

  /// Hàm lấy dữ liệu từ DB (Có lọc theo Category và Security)
  Future<void> fetchAllLinks({bool isInitial = false}) async {
    if (!_canLoadMore) return;

    final CustomPopupController categoryPopup = DependencyUtils.put(() => CustomPopupController());

    try {
      if (isInitial) {
        isLoading.value = true;
      } else {
        isLoadMore.value = true;
      }

      final selectedCategoryId = categoryPopup.selectedItem.value?.id;
      final bool isSecurityEnabled = AppGetStorage.isCategorySecurity();

      // --- PHẦN LOGIC LỌC SQL (QUAN TRỌNG NHẤT) ---
      String? whereClause;
      List<dynamic>? whereArgs;

      if (selectedCategoryId != null && selectedCategoryId != 'all') {
        // 1. Lọc theo danh mục được chọn
        whereClause = 'categoryId = ?';
        whereArgs = [selectedCategoryId];
      } else if (isSecurityEnabled) {
        // 2. Nếu chọn "Tất cả" nhưng có bật bảo mật -> Ẩn các link thuộc Category Private
        Set<String?> privateCategoryIds = {};
        if (categoryPopup.items.isNotEmpty) {
          privateCategoryIds = categoryPopup.items
              .where((item) => item.visibility == VisibilityStatus.private)
              .map((item) => item.id)
              .toSet();
        } else {
          final catRows = await DbHelper.getAll('categories');
          privateCategoryIds = catRows
              .where((row) => row['visibility'] == VisibilityStatus.private.name)
              .map((row) => row['id'] as String?)
              .toSet();
        }

        if (privateCategoryIds.isNotEmpty) {
          final placeholders = privateCategoryIds.map((_) => '?').join(', ');
          whereClause = 'categoryId NOT IN ($placeholders) OR categoryId IS NULL';
          whereArgs = privateCategoryIds.toList();
        }
      }

      // --- TRUY VẤN DATABASE ---
      final linkRows = await DbHelper.getAll(
        'links',
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        where: whereClause,
        whereArgs: whereArgs,
      );

      if (linkRows.isEmpty) {
        _canLoadMore = false;
      } else {
        final List<LinkModel> fetchedItems = linkRows
            .map((row) => LinkModel.fromJson(Map<String, dynamic>.from(row)))
            .toList();

        listLink.addAll(fetchedItems);
        _currentPage++;

        // Nếu số bản ghi lấy ra ít hơn pageSize thì trang sau chắc chắn hết
        if (linkRows.length < _pageSize) {
          _canLoadMore = false;
        }
      }

      log('Page ${_currentPage - 1} loaded. Total displayed: ${listLink.length}');
    } catch (e) {
      log('Error fetching links: $e');
    } finally {
      isLoading.value = false;
      isLoadMore.value = false;
    }
  }

  Future<void> loadMore() async {
    await fetchAllLinks(isInitial: false);
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
          Get.back();
          Fluttertoast.showToast(msg: "Đã xóa");
        },
        onCancel: () => Get.back(),
      );
    } catch (e) {
      log("Error deleting link: $e");
    }
  }

  Future<void> onRefreshData() async {
    await refreshData(showToast: true);
    if (Get.isRegistered<CategoryController>()) {
      await Get.find<CategoryController>().refreshCategory();
    }
  }

  void clearLinks() => listLink.clear();
}
