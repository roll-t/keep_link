import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/data/repositories/category_repository.dart';
import 'package:keep_link/core/data/repositories/link_repository.dart';
import 'package:keep_link/core/di/dependency_utils.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/features/category/presentation/controller/category_controller.dart';
import 'package:keep_link/features/category/presentation/controller/custom_popup_controller.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

class LinkCollectionController extends GetxController {
  // --- State Variables ---
  final RxList<LinkModel> listLink = <LinkModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoadMore = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool isDeleting = false.obs;

  // --- Selection Mode ---
  final RxBool isSelectionMode = false.obs;
  final RxSet<String> selectedIds = <String>{}.obs;

  bool get isAllSelected =>
      listLink.isNotEmpty && selectedIds.length == listLink.length;

  void enterSelectionMode(String firstId) {
    isSelectionMode.value = true;
    selectedIds.add(firstId);
  }

  void exitSelectionMode() {
    isSelectionMode.value = false;
    selectedIds.clear();
  }

  void toggleSelectItem(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
      if (selectedIds.isEmpty) exitSelectionMode();
    } else {
      selectedIds.add(id);
    }
  }

  void toggleSelectAll() {
    if (isAllSelected) {
      selectedIds.clear();
    } else {
      selectedIds.addAll(listLink.map((e) => e.id));
    }
  }

  Future<void> deleteSelectedLinks() async {
    final idsToDelete = List<String>.from(selectedIds);
    if (idsToDelete.isEmpty || isDeleting.value) return;
    DialogUtils.showConfirm(
      alertType: AlertType.warning,
      title: "Xác nhận",
      content: "Bạn chắc chắn muốn xóa ${idsToDelete.length} link đã chọn?",
      onConfirm: () async {
        Get.back();
        isDeleting.value = true;
        try {
          // Revoke every receiver's access first. If Firebase is unavailable,
          // keep the owner's links intact instead of deleting locally while a
          // stale share is still visible on another account.
          await FirebaseService.revokeAllLinksShares(idsToDelete);
          await LinkRepository.deleteAll(idsToDelete);
          final idSet = idsToDelete.toSet();
          listLink.removeWhere((item) => idSet.contains(item.id));
          _filteredLinks?.removeWhere((item) => idSet.contains(item.id));
          exitSelectionMode();

          AppToast.showToast(
            'Đã xóa ${idsToDelete.length} link',
            Icons.delete_outline_rounded,
          );
        } catch (error) {
          log('Delete selected links error: $error');
          AppToast.showToast(
            'An error occurred, please try again'.tr,
            Icons.error_outline_rounded,
            color: AppColors.danger,
          );
        } finally {
          isDeleting.value = false;
        }
      },
      onCancel: () => Get.back(),
    );
  }

  // --- Pagination Variables ---
  final ScrollController scrollController = ScrollController();
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _canLoadMore = true;
  Future<void>? _refreshFuture;
  bool _refreshQueued = false;

  // Toàn bộ danh sách đã áp filter category/privacy hiện tại — tính 1 lần
  // mỗi khi filter đổi (refreshData), các lần loadMore() sau chỉ cắt lát ra
  // từ đây. Trước đây mỗi lần kéo thêm 1 trang là quét lại TOÀN BỘ
  // AppCache.links từ đầu (LinkRepository.getFilteredPage) — cuộn hết 1 danh
  // sách N link tốn O(N²) thay vì O(N).
  List<LinkModel>? _filteredLinks;

  List<LinkModel> _getLinksForSelectedCategory(String? categoryId) {
    final isAllCategory = categoryId == null || categoryId == 'all';
    final isCategorySecurityEnabled = AppGetStorage.isCategorySecurity();
    return LinkRepository.getFiltered(
      categoryId: categoryId,
      privateCategoryIds: AppCache.privateCategoryIds,
      // The aggregate view must never leak links from locked categories.
      // A private category is only queried directly after its unlock flow.
      excludePrivate: isCategorySecurityEnabled && isAllCategory,
    );
  }

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
    if (!scrollController.hasClients) return;
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      if (!isLoading.value && !isLoadMore.value && _canLoadMore) {
        loadMore();
      }
    }
  }

  Future<void> refreshData({bool showToast = false}) async {
    final active = _refreshFuture;
    if (active != null) {
      // Filter có thể đã đổi trong lúc refresh trước đang chạy. Gộp mọi lời
      // gọi đồng thời thành tối đa một lượt chạy lại với state mới nhất.
      _refreshQueued = true;
      return active;
    }

    final future = _performRefresh(showToast: showToast);
    _refreshFuture = future;
    try {
      await future;
    } finally {
      if (identical(_refreshFuture, future)) _refreshFuture = null;
    }

    if (_refreshQueued) {
      _refreshQueued = false;
      await refreshData();
    }
  }

  Future<void> _performRefresh({required bool showToast}) async {
    final hasContent = listLink.isNotEmpty;
    errorMessage.value = null;
    if (hasContent) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }

    try {
      await Future.wait([
        LinkRepository.ensureLoaded(),
        CategoryRepository.ensureLoaded(),
      ]);

      final categoryPopup = Get.find<CustomPopupController>();
      final selectedCategoryId = categoryPopup.selectedItem.value?.id;
      final filtered = _getLinksForSelectedCategory(selectedCategoryId);
      _filteredLinks = filtered;
      _currentPage = filtered.isEmpty ? 0 : 1;
      _canLoadMore = filtered.length > _pageSize;

      // Một lần assign duy nhất: giữ nội dung cũ trong lúc refresh và tránh
      // chuỗi clear → addAll gây hai frame rebuild/nháy grid.
      listLink.assignAll(filtered.take(_pageSize));

      if (showToast) {
        AppToast.showToast(
          "Refreshed".tr,
          Icons.check_circle_rounded,
          color: AppColors.success,
        );
      }
    } catch (error) {
      log('Refresh links error: $error');
      errorMessage.value = 'An error occurred, please try again'.tr;
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> fetchAllLinks({bool isInitial = false}) async {
    if (isInitial) return refreshData();
    if (!_canLoadMore) return;
    final CustomPopupController categoryPopup = DependencyUtils.put(
      () => CustomPopupController(),
    );
    try {
      if (isInitial) {
        isLoading.value = true;
      } else {
        isLoadMore.value = true;
      }

      // Ensure both caches are populated (DB query only on very first call).
      await Future.wait([
        LinkRepository.ensureLoaded(),
        CategoryRepository.ensureLoaded(),
      ]);

      // Filter cache from AppCache — pure in-memory, no I/O. Computed once
      // per filter (reset in refreshData()); loadMore() just slices pages
      // out of it instead of re-scanning every link again each time.
      if (_filteredLinks == null) {
        final selectedCategoryId = categoryPopup.selectedItem.value?.id;
        _filteredLinks = _getLinksForSelectedCategory(selectedCategoryId);
      }

      final source = _filteredLinks!;
      final offset = _currentPage * _pageSize;
      final page = offset >= source.length
          ? const <LinkModel>[]
          : source.skip(offset).take(_pageSize).toList();

      if (page.isEmpty) {
        _canLoadMore = false;
      } else {
        listLink.addAll(page);
        _currentPage++;
        if (page.length < _pageSize) _canLoadMore = false;
      }

      log(
        'Page $_currentPage loaded (cache). Total displayed: ${listLink.length}',
      );
    } catch (e) {
      log('Error fetching links: $e');
    } finally {
      isLoading.value = false;
      isLoadMore.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_refreshFuture != null || isLoadMore.value) return;
    await fetchAllLinks(isInitial: false);
  }

  Future<void> onDeleteLink(String id) async {
    try {
      DialogUtils.showConfirm(
        alertType: AlertType.warning,
        title: "Xác nhận",
        content: "Bạn chắc chắn muốn xóa link!",
        onConfirm: () async {
          Get.back();
          try {
            // Access is revoked before the owner's local/remote delete is
            // queued, so receivers lose the item immediately and atomically.
            await FirebaseService.revokeAllLinkShares(id);
            await LinkRepository.delete(id);
            listLink.removeWhere((item) => item.id == id);
            _filteredLinks?.removeWhere((item) => item.id == id);
            Get.back();
            AppToast.showToast("Deleted".tr, Icons.delete_outline_rounded);
          } catch (error) {
            log('Delete link error: $error');
            AppToast.showToast(
              'An error occurred, please try again'.tr,
              Icons.error_outline_rounded,
              color: AppColors.danger,
            );
          }
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
    _filteredLinks = null;
  }
}
