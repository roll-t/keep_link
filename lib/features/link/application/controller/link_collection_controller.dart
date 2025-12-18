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
import 'package:keep_link/features/link/data/model/link_model.dart';

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

  void _scrollListener() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (!isLoading.value && !isLoadMore.value && _canLoadMore) {
        loadMore();
      }
    }
  }

  /// Hàm Refresh data (gọi khi kéo để làm mới hoặc đổi category)
  Future<void> refreshData({bool showToast = false}) async {
    _currentPage = 0;
    _canLoadMore = true;
    listLink.clear();
    await fetchAllLinks(isInitial: true);

    if (showToast) {
      Fluttertoast.showToast(msg: "Đã cập nhật dữ liệu");
    }
  }

  /// Hàm chính để lấy dữ liệu từ DB
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
      Set<String?> privateCategoryIds = {};

      if (isSecurityEnabled) {
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
      }

      final linkRows = await DbHelper.getAll(
        'links',
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (linkRows.isEmpty) {
        _canLoadMore = false;
        return;
      }

      List<LinkModel> filteredLinks = [];
      if (selectedCategoryId == 'all' || selectedCategoryId == null) {
        filteredLinks = linkRows
            .where((row) => !privateCategoryIds.contains(row['categoryId']))
            .map((row) => LinkModel.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      } else {
        filteredLinks = linkRows
            .where((row) => row['categoryId'] == selectedCategoryId)
            .map((row) => LinkModel.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      }

      if (filteredLinks.isNotEmpty) {
        listLink.addAll(filteredLinks);
        _currentPage++;
      }

      if (linkRows.length < _pageSize) {
        _canLoadMore = false;
      }

      log('Loaded page ${_currentPage - 1}. Total: ${listLink.length} items.');
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

  void clearLinks() {
    listLink.clear();
  }
}
