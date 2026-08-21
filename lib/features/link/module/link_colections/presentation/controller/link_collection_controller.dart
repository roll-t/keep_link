import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
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
  final RxBool isLoadMore = false.obs;

  // --- Selection Mode ---
  final RxBool isSelectionMode = false.obs;
  final RxSet<String> selectedIds = <String>{}.obs;

  bool get isAllSelected => listLink.isNotEmpty && selectedIds.length == listLink.length;

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
      exitSelectionMode();
    } else {
      selectedIds.addAll(listLink.map((e) => e.id));
    }
  }

  Future<void> deleteSelectedLinks() async {
    final idsToDelete = List<String>.from(selectedIds);
    if (idsToDelete.isEmpty) return;
    DialogUtils.showConfirm(
      alertType: AlertType.warning,
      title: "Xác nhận",
      content: "Bạn chắc chắn muốn xóa ${idsToDelete.length} link đã chọn?",
      onConfirm: () async {
        Get.back();
        for (final id in idsToDelete) {
          await LinkRepository.delete(id);
        }
        listLink.removeWhere((item) => idsToDelete.contains(item.id));
        // Giữ đồng bộ với cache lọc — nếu không, loadMore() sau đó sẽ cắt
        // lát từ 1 danh sách còn dính các link vừa xoá, làm lệch offset và
        // âm thầm bỏ sót/lặp item ở các trang tiếp theo.
        _filteredLinks?.removeWhere((item) => idsToDelete.contains(item.id));
        exitSelectionMode();
        AppToast.showToast('Đã xóa ${idsToDelete.length} link', Icons.delete_outline_rounded);
      },
      onCancel: () => Get.back(),
    );
  }

  // --- Pagination Variables ---
  final ScrollController scrollController = ScrollController();
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _canLoadMore = true;

  // Toàn bộ danh sách đã áp filter category/privacy hiện tại — tính 1 lần
  // mỗi khi filter đổi (refreshData), các lần loadMore() sau chỉ cắt lát ra
  // từ đây. Trước đây mỗi lần kéo thêm 1 trang là quét lại TOÀN BỘ
  // AppCache.links từ đầu (LinkRepository.getFilteredPage) — cuộn hết 1 danh
  // sách N link tốn O(N²) thay vì O(N).
  List<LinkModel>? _filteredLinks;

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
    _filteredLinks = null;
    listLink.clear();
    await fetchAllLinks(isInitial: true);

    if (showToast) {
      AppToast.showToast("Refreshed".tr, Icons.check_circle_rounded, color: Colors.green);
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

      // Filter cache from AppCache — pure in-memory, no I/O. Computed once
      // per filter (reset in refreshData()); loadMore() just slices pages
      // out of it instead of re-scanning every link again each time.
      if (_filteredLinks == null) {
        final selectedCategoryId = categoryPopup.selectedItem.value?.id;
        final bool isSecurityEnabled = AppGetStorage.isCategorySecurity();

        // Compute private IDs from in-memory cache — no DB query.
        final Set<String> privateCategoryIds = isSecurityEnabled
            ? AppCache.privateCategoryIds
            : const {};

        // Only exclude private categories when browsing "All" — if the user has
        // explicitly selected a specific (private) category they already passed
        // the PIN/biometric check, so their links must be shown.
        final bool isAllCategory = selectedCategoryId == null || selectedCategoryId == 'all';
        _filteredLinks = LinkRepository.getFiltered(
          categoryId: selectedCategoryId,
          privateCategoryIds: privateCategoryIds,
          excludePrivate: isSecurityEnabled && isAllCategory,
        );
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

      log('Page $_currentPage loaded (cache). Total displayed: ${listLink.length}');
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
          FirebaseService.revokeAllLinkShares(id);
          listLink.removeWhere((item) => item.id == id);
          _filteredLinks?.removeWhere((item) => item.id == id);
          Get.back();
          Get.back();
          AppToast.showToast("Deleted".tr, Icons.delete_outline_rounded);
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
