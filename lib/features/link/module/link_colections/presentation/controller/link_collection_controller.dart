import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/cache/app_cache.dart';
import 'package:keep_link/core/cache/app_get_storage.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/repository/category_repository.dart';
import 'package:keep_link/core/repository/link_repository.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/features/category/presentation/controller/category_controller.dart';
import 'package:keep_link/features/category/presentation/controller/custom_popup_controller.dart';
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

  void _scrollListener() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (!isLoading.value && !isLoadMore.value && _canLoadMore) {
        loadMore();
      }
    }
  }

  Future<void> refreshData({bool showToast = false}) async {
    _currentPage = 0;
    _canLoadMore = true;
    listLink.clear();
    await fetchAllLinks(isInitial: true);

    if (showToast) {
      Fluttertoast.showToast(msg: "Đã làm mới");
    }
  }

  Future<void> fetchAllLinks({bool isInitial = false}) async {
    if (!_canLoadMore) return;
    final CustomPopupController categoryPopup = DependencyUtils.put(() => CustomPopupController());
    try {
      if (isInitial) {
        isLoading.value = true;
      } else {
        isLoadMore.value = true;
      }

      // Ensure both caches are populated (DB query only on very first call).
      await Future.wait([LinkRepository.ensureLoaded(), CategoryRepository.ensureLoaded()]);

      final selectedCategoryId = categoryPopup.selectedItem.value?.id;
      final bool isSecurityEnabled = AppGetStorage.isCategorySecurity();

      // Compute private IDs from in-memory cache — no DB query.
      final Set<String> privateCategoryIds = isSecurityEnabled
          ? AppCache.privateCategoryIds
          : const {};

      // Page from cache — pure in-memory, no I/O.
      final page = LinkRepository.getFilteredPage(
        categoryId: selectedCategoryId,
        privateCategoryIds: privateCategoryIds,
        excludePrivate: isSecurityEnabled,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (page.isEmpty) {
        _canLoadMore = false;
      } else {
        listLink.addAll(page);
        _currentPage++;
        if (page.length < _pageSize) _canLoadMore = false;
      }

      log('Page ${_currentPage - 1} loaded (cache). Total displayed: ${listLink.length}');
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
          await LinkRepository.delete(id);
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
