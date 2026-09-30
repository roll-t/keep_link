import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/data/models/item_model.dart';
import 'package:keep_link/core/data/repositories/category_repository.dart';
import 'package:keep_link/core/services/platform/deep_link_service.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/core/di/dependency_utils.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/core/utils/link_source_util.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/application/category_name_rules.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';
import 'package:keep_link/features/category/presentation/controller/custom_popup_controller.dart';
import 'package:keep_link/features/category/presentation/widget/category_dialog.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/link_collection_controller.dart';

class CategoryController extends GetxController {
  final categoryNameController = TextEditingController();
  final FocusNode nameFocusNode = FocusNode();
  final CustomPopupController popupController = DependencyUtils.put(
    () => CustomPopupController(),
  );

  // State
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxString errorMess = "".obs;
  final Rx<VisibilityStatus> visibility = VisibilityStatus.public.obs;
  final RxSet<String> pinnedCategoryIds = <String>{}.obs;
  final RxBool isCategorySaving = false.obs;
  bool _isFormPrepared = false;

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
    nameFocusNode.dispose();
    super.onClose();
  }

  /// -----------------------------
  /// CORE: FETCH & REFRESH (Gộp logic)
  /// -----------------------------
  Future<void> fetchCategories({bool keepSelection = false}) async {
    // Load from cache (no DB hit if already loaded).
    await CategoryRepository.ensureLoaded();
    List<CategoryModel> loadedList = CategoryRepository.getAll().toList();

    _sortCategories(loadedList);
    categories.assignAll(loadedList);

    final currentSelectedId = keepSelection
        ? popupController.selectedItem.value?.id
        : null;
    _recomputeSources();
    _updatePopupItems(selectId: currentSelectedId);

    // Tải danh sách share 1 lần (nếu đăng nhập & cache chưa có)
    if (FirebaseService.currentUser != null &&
        AppCache.sharedWithCache.isEmpty) {
      _loadSharedWithCache(loadedList);
    }
  }

  /// -----------------------------
  /// CREATE
  /// -----------------------------
  Future<void> addCategory() async {
    if (isCategorySaving.value || !_validateCategory()) return;

    isCategorySaving.value = true;

    try {
      final now = DateTime.now();
      final category = CategoryModel(
        id: now.microsecondsSinceEpoch.toString(),
        name: _cleanCategoryName(),
        createdAt: now,
        visibility: visibility.value,
      );

      await CategoryRepository.insert(category);

      // Write-through: cache already updated inside CategoryRepository.insert.
      // Just sync the local UI list.
      categories.insert(0, category);
      _updatePopupItems(selectId: category.id);

      if (!DeepLinkService.isOpenedFromShare) {
        await _reloadLinks();
      }
      isCategorySaving.value = false;
      _closeCategoryDialog();
    } catch (e, s) {
      _handleError('Add category error', e, s);
    } finally {
      isCategorySaving.value = false;
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
    if (isCategorySaving.value) return;

    final selected = popupController.selectedItem.value;
    if (selected == null || selected.id == 'all') return;

    if (!_validateCategory(checkLimit: false, editingId: selected.id)) return;

    final index = categories.indexWhere((e) => e.id == selected.id);
    if (index == -1) return;

    final current = categories[index];
    final cleanedName = _cleanCategoryName();

    // Avoid a DB write and sync event when the user did not change anything.
    if (current.name == cleanedName && current.visibility == visibility.value) {
      _closeCategoryDialog();
      return;
    }

    final categoryUpdate = CategoryModel(
      id: current.id,
      name: cleanedName,
      description: current.description,
      iconUrl: current.iconUrl,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      visibility: visibility.value,
    );

    isCategorySaving.value = true;
    try {
      await CategoryRepository.update(categoryUpdate);
      AppToast.success("Update successful".tr);

      categories[index] = categoryUpdate;
      _sortCategories(categories);
      categories.refresh();

      _updatePopupItems(selectId: categoryUpdate.id);
      await _reloadLinks();
      isCategorySaving.value = false;
      _closeCategoryDialog();
    } catch (e, s) {
      _handleError('Update category error', e, s);
    } finally {
      isCategorySaving.value = false;
    }
  }

  /// -----------------------------
  /// DELETE
  /// -----------------------------
  Future<void> deleteCategory() async {
    final selected = popupController.selectedItem.value;
    if (selected == null || selected.id == 'all') return;

    final hasLinks = AppCache.links.any(
      (link) => link.categoryId == selected.id,
    );
    if (hasLinks) {
      AppToast.warning("Category contains links\nCannot delete!".tr);
      return;
    }

    DialogUtils.showConfirm(
      alertType: AlertType.warning,
      title: "Confirm".tr,
      content: "Are you sure you want to delete!".tr,
      barrierDismissible: false,
      onConfirm: () async {
        if (isCategorySaving.value) return;
        isCategorySaving.value = true;
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
          final newSelectedId = categories.isNotEmpty
              ? categories.first.id
              : 'all';
          _updatePopupItems(selectId: newSelectedId);
          await _reloadLinks();

          // Confirm dialog is on top of the category editor. Close both in a
          // deterministic order so an async completion never pops a page.
          isCategorySaving.value = false;
          if (Get.isDialogOpen == true) Get.back();
          await Future<void>.delayed(const Duration(milliseconds: 50));
          closeCategoryDialog(force: true);
        } catch (e, s) {
          _handleError('Delete category error', e, s);
        } finally {
          isCategorySaving.value = false;
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
      final aTime =
          a.createdAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          b.createdAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
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
    _recomputeSources();
    _updatePopupItems(selectId: popupController.selectedItem.value?.id);
  }

  void _recomputeSources() {
    final sources = LinkSourceUtil.computeSources(
      AppCache.links,
      privateCategoryIds: AppCache.privateCategoryIds,
    );
    final sourceItemList = [
      ItemModel(id: "all", name: "All".tr),
      ...sources.map(
        (s) => ItemModel(
          id: "source:${s.host}",
          name: s.label,
          chilrenCount: s.count,
          isSource: true,
          sourceHost: s.host,
        ),
      ),
    ];
    popupController.sourceItems.assignAll(sourceItemList);
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

    final currentSelected = popupController.selectedItem.value;
    if (currentSelected?.isSource == true) {
      final matchedSource = popupController.sourceItems.firstWhereOrNull(
        (e) => e.id == currentSelected!.id,
      );
      if (matchedSource != null) {
        popupController.selectedItem.value = matchedSource;
        return;
      }
    }

    if (selectId != null) {
      final matched = newItems.firstWhere(
        (e) => e.id == selectId,
        orElse: () => newItems.first,
      );
      popupController.selectedItem.value = matched;
    } else {
      popupController.selectedItem.value ??= newItems.first;
    }
  }

  bool _validateCategory({bool checkLimit = true, String? editingId}) {
    if (checkLimit && AppCache.categories.length >= _maxCategories) {
      AppToast.warning("max_categories_limit".trArgs(["$_maxCategories"]));
      return false;
    }

    final name = _cleanCategoryName();
    if (name.isEmpty) {
      errorMess.value = "Tên danh mục không được bỏ trống";
      return false;
    }

    if (name.length > CategoryNameRules.maxLength) {
      errorMess.value =
          "Tên danh mục không được vượt quá ${CategoryNameRules.maxLength} ký tự";
      return false;
    }

    if (CategoryNameRules.isReserved(name, 'All'.tr) ||
        CategoryNameRules.comparisonKey(name) == 'all') {
      errorMess.value = "Tên danh mục này đã được sử dụng";
      return false;
    }

    final duplicated = CategoryNameRules.isDuplicate(
      name,
      categories,
      editingId: editingId,
    );
    if (duplicated) {
      errorMess.value = "Tên danh mục đã tồn tại";
      return false;
    }

    errorMess.value = "";
    return true;
  }

  String _cleanCategoryName() =>
      CategoryNameRules.clean(categoryNameController.text);

  void _handleError(String msg, Object e, StackTrace s) {
    debugPrint('$msg: $e');
    debugPrintStack(stackTrace: s);
    AppToast.error("An error occurred, please try again".tr);
  }

  Future<void> _reloadLinks() async {
    if (Get.isRegistered<LinkCollectionController>()) {
      await Get.find<LinkCollectionController>().refreshData();
    }
  }

  void closeCategoryDialog({bool force = false}) {
    if (!force && isCategorySaving.value) return;
    _isFormPrepared = false;
    Utils.dimissKeyboard();
    categoryNameController.clear();
    if (Get.isDialogOpen == true) Get.back();
  }

  void _closeCategoryDialog() => closeCategoryDialog(force: true);

  /// Ensures form state is reset exactly once when a category dialog opens.
  void ensureFormPrepared({required bool isEditMode}) {
    if (!_isFormPrepared) {
      _isFormPrepared = true;
      prepareCategoryForm(isEditMode: isEditMode);
    }
  }

  /// Resets form state and requests focus for category dialog.
  void prepareCategoryForm({required bool isEditMode}) {
    errorMess.value = "";

    if (!isEditMode) {
      categoryNameController.clear();
      visibility.value = VisibilityStatus.public;
    } else {
      final selectedId = popupController.selectedItem.value?.id;
      final selected = categories.firstWhereOrNull(
        (item) => item.id == selectedId,
      );
      categoryNameController.text = selected?.name ?? "";
      visibility.value = selected?.visibility ?? VisibilityStatus.public;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (nameFocusNode.canRequestFocus) {
        nameFocusNode.requestFocus();
      }
    });
  }

  void openCategoryDialog({bool isEditMode = false}) {
    _isFormPrepared = true;
    prepareCategoryForm(isEditMode: isEditMode);
    Get.dialog(
      CategoryDialog(isEditMode: isEditMode),
      barrierDismissible: false,
    );
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

  Future<void> onSelectedCategory() async {
    visibility.value =
        popupController.selectedItem.value?.visibility ??
        VisibilityStatus.public;
    await _reloadLinks();
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
      await _reloadLinks();
      AppToast.success(
        newVisibility == VisibilityStatus.private
            ? 'Đã đặt riêng tư'
            : 'Đã đặt công khai',
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
      final sharedUids = await FirebaseService.getCategorySharedFriendUids(
        categoryId,
      );
      return AppCache.friends
          .where((f) => sharedUids.contains(f.friendUserId))
          .toList();
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
      AppToast.warning('share_sign_in_required'.tr);
      return;
    }

    final friendUid = friend.friendUserId;
    if (friendUid.isEmpty) return;

    try {
      if (currentlyShared) {
        await FirebaseService.unshareCategory(
          friendUid: friendUid,
          categoryId: categoryId,
        );
        AppCache.removeSharedFriend(categoryId, friendUid);
        AppToast.warning('category_unshared'.tr);
      } else {
        await FirebaseService.shareCategory(
          friendUid: friendUid,
          categoryId: categoryId,
        );
        AppCache.addSharedFriend(categoryId, friend);
        AppToast.success('category_shared'.tr);
      }
      onSuccess();
    } catch (e) {
      _handleError('Toggle share error', e, StackTrace.current);
    }
  }
}
