import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/data/models/item_model.dart';
import 'package:keep_link/core/data/repositories/category_repository.dart';
import 'package:keep_link/core/services/platform/deep_link_service.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/core/di/dependency_utils.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';
import 'package:keep_link/features/category/presentation/controller/custom_popup_controller.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/link_collection_controller.dart';

class CategoryController extends GetxController {
  final categoryNameController = TextEditingController();
  final CustomPopupController popupController = DependencyUtils.put(() => CustomPopupController());

  // State
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxString errorMess = "".obs;
  final Rx<VisibilityStatus> visibility = VisibilityStatus.public.obs;
  final RxSet<String> pinnedCategoryIds = <String>{}.obs;

  // Constants
  static const int _maxCategories = 30;

  @override
  void onInit() {
    super.onInit();
    categoryNameController.clear();
    pinnedCategoryIds.addAll(AppGetStorage.getPinnedCategoryIds());
    fetchCategories();
    ever(AppCache.links, (_) => _recomputeChildrenCounts());
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
    // Load from cache (no DB hit if already loaded).
    await CategoryRepository.ensureLoaded();
    List<CategoryModel> loadedList = CategoryRepository.getAll().toList();

    if (loadedList.isEmpty) {
      final defaultCategory = await _createDefaultCategory();
      loadedList.add(defaultCategory);
    }
    _sortCategories(loadedList);
    categories.assignAll(loadedList);

    final currentSelectedId = keepSelection ? popupController.selectedItem.value?.id : null;
    _updatePopupItems(selectId: currentSelectedId);

    // Tải danh sách share 1 lần (nếu đăng nhập & cache chưa có)
    if (FirebaseService.currentUser != null && AppCache.sharedWithCache.isEmpty) {
      _loadSharedWithCache(loadedList);
    }
  }

  Future<CategoryModel> _createDefaultCategory() async {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final defaultCategory = CategoryModel(id: id, name: "Category".tr, createdAt: now);
    await CategoryRepository.insert(defaultCategory);
    // Mark this category as guest-only so it is excluded from being pushed
    // to a signed-in account that already has its own data.
    AppGetStorage.setGuestDefaultCategoryId(id);
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

      await CategoryRepository.insert(category);

      // Write-through: cache already updated inside CategoryRepository.insert.
      // Just sync the local UI list.
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
    // checkLimit: false — đây là sửa 1 category ĐÃ CÓ, không phải thêm mới.
    // Dùng chung _validateCategory() mặc định sẽ luôn chặn vì "đang sửa 1
    // trong 30 category" tức là count đã >= 30, khoá luôn cả việc đổi tên
    // hay đổi visibility 1 khi đã chạm giới hạn.
    if (!_validateCategory(checkLimit: false)) return;

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
      await CategoryRepository.update(categoryUpdate);
      Fluttertoast.showToast(msg: "Update successful".tr);

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
      Fluttertoast.showToast(msg: "Category contains links\nCannot delete!".tr);
      return;
    }

    DialogUtils.showConfirm(
      alertType: AlertType.warning,
      title: "Confirm".tr,
      content: "Are you sure you want to delete!".tr,
      onConfirm: () async {
        try {
          final id = selected.id ?? "";
          await CategoryRepository.delete(id);

          // Dọn luôn các bản ghi share ở Firebase (sharedWith / sharedCategoryAccess)
          // — nếu không, category đã xoá vẫn còn nằm rải rác trong node của
          // mình và của bạn bè đã được share, tồn tại vĩnh viễn không ai dọn.
          if (FirebaseService.currentUser != null) {
            unawaited(FirebaseService.revokeAllCategoryShares(id));
          }
          AppCache.sharedWithCache.remove(id);

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
      final aPinned = pinnedCategoryIds.contains(a.id);
      final bPinned = pinnedCategoryIds.contains(b.id);
      if (aPinned != bPinned) return aPinned ? -1 : 1;
      final aTime = a.createdAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  void _recomputeChildrenCounts() {
    final counts = <String, int>{};
    for (final link in AppCache.links) {
      final cid = link.categoryId;
      if (cid == null || cid.isEmpty) continue;
      counts[cid] = (counts[cid] ?? 0) + 1;
    }
    for (final cat in categories) {
      cat.chilrenCount = counts[cat.id] ?? 0;
    }
    _updatePopupItems(selectId: popupController.selectedItem.value?.id);
  }

  void _updatePopupItems({String? selectId}) {
    final newItems = [
      ItemModel(id: "all", name: "All".tr),
      ...categories.map(
        (c) => ItemModel(
          id: c.id,
          name: c.name,
          visibility: c.visibility,
          chilrenCount: c.chilrenCount,
          isPinned: pinnedCategoryIds.contains(c.id),
        ),
      ),
    ];

    popupController.items.assignAll(newItems);

    if (selectId != null) {
      final matched = newItems.firstWhere((e) => e.id == selectId, orElse: () => newItems.first);
      popupController.selectedItem.value = matched;
    } else {
      popupController.selectedItem.value ??= newItems.first;
    }
  }

  bool _validateCategory({bool checkLimit = true}) {
    if (checkLimit && categories.length >= _maxCategories) {
      Fluttertoast.showToast(msg: "max_categories_limit".trArgs(["$_maxCategories"]));
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
    Fluttertoast.showToast(msg: "An error occurred, please try again".tr);
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
    await CategoryRepository.clearAll();
    categories.clear();
    _updatePopupItems();
  }

  void setVisibility(VisibilityStatus value) => visibility.value = value;

  void onSelectedCategory() {
    visibility.value = popupController.selectedItem.value?.visibility ?? VisibilityStatus.public;
    _reloadLinks();
  }

  // ── Visibility Toggle ────────────────────────────────────────────────────

  Future<void> toggleCategoryVisibility(String categoryId) async {
    final index = categories.indexWhere((e) => e.id == categoryId);
    if (index == -1) return;

    final current = categories[index];
    final newVisibility = current.visibility == VisibilityStatus.private
        ? VisibilityStatus.public
        : VisibilityStatus.private;

    final updated = CategoryModel(
      id: current.id,
      name: current.name,
      description: current.description,
      iconUrl: current.iconUrl,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      visibility: newVisibility,
    );

    try {
      await CategoryRepository.update(updated);
      categories[index] = updated;
      _sortCategories(categories);
      categories.refresh();
      _updatePopupItems(selectId: updated.id);
      Fluttertoast.showToast(
        msg: newVisibility == VisibilityStatus.private ? 'Đã đặt riêng tư' : 'Đã đặt công khai',
      );
    } catch (e, s) {
      _handleError('Toggle visibility error', e, s);
    }
  }

  // ── Pin ───────────────────────────────────────────────────────────────────

  void togglePinCategory(String categoryId) {
    if (pinnedCategoryIds.contains(categoryId)) {
      pinnedCategoryIds.remove(categoryId);
    } else {
      pinnedCategoryIds.add(categoryId);
    }
    AppGetStorage.setPinnedCategoryIds(Set.from(pinnedCategoryIds));
    _sortCategories(categories);
    categories.refresh();
    _updatePopupItems(selectId: popupController.selectedItem.value?.id);
  }

  bool isCategoryPinned(String? categoryId) =>
      categoryId != null && pinnedCategoryIds.contains(categoryId);

  // ── Share ─────────────────────────────────────────────────────────────────

  /// Bulk-load shared-with info for all categories in one Firebase read.
  /// Stores result in [AppCache.sharedWithCache] — only called once per session.
  Future<void> _loadSharedWithCache(List<CategoryModel> cats) async {
    try {
      final uid = FirebaseService.currentUser?.uid;
      if (uid == null) return;

      // Fetch entire sharedWith node: users/$uid/sharedWith
      final sharedWithMap = await FirebaseService.getAllSharedWith();
      // sharedWithMap: { friendUid: { catId: true, ... }, ... }

      // Build reverse map: catId → [FriendModel, ...]
      final result = <String, List<FriendModel>>{};
      for (final entry in sharedWithMap.entries) {
        final friendUid = entry.key;
        final catIds = entry.value;
        final friend = AppCache.friends.firstWhere(
          (f) => f.friendUserId == friendUid,
          orElse: () => FriendModel(friendUserId: friendUid),
        );
        for (final catId in catIds) {
          result.putIfAbsent(catId, () => []).add(friend);
        }
      }

      AppCache.setSharedWith(result);
    } catch (_) {}
  }

  /// Returns the list of friends this [categoryId] is currently shared with.
  /// Result is a list of [FriendModel]s that have access.
  Future<List<FriendModel>> getCategorySharedFriends(String categoryId) async {
    if (FirebaseService.currentUser == null) return [];
    try {
      final sharedUids = await FirebaseService.getCategorySharedFriendUids(categoryId);
      return AppCache.friends.where((f) => sharedUids.contains(f.friendUserId)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Toggle sharing [categoryId] with [friend].
  /// If already shared → unshare; otherwise → share.
  Future<void> toggleCategoryShare({
    required String categoryId,
    required FriendModel friend,
    required bool currentlyShared,
    required VoidCallback onSuccess,
  }) async {
    if (FirebaseService.currentUser == null) {
      Fluttertoast.showToast(msg: 'share_sign_in_required'.tr);
      return;
    }

    final friendUid = friend.friendUserId;
    if (friendUid.isEmpty) return;

    try {
      if (currentlyShared) {
        await FirebaseService.unshareCategory(friendUid: friendUid, categoryId: categoryId);
        AppCache.removeSharedFriend(categoryId, friendUid);
        Fluttertoast.showToast(msg: 'category_unshared'.tr);
      } else {
        await FirebaseService.shareCategory(friendUid: friendUid, categoryId: categoryId);
        AppCache.addSharedFriend(categoryId, friend);
        Fluttertoast.showToast(msg: 'category_shared'.tr);
      }
      onSuccess();
    } catch (e) {
      _handleError('Toggle share error', e, StackTrace.current);
    }
  }
}
