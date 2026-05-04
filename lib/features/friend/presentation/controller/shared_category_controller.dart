import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/cache/app_get_storage.dart';
import 'package:keep_link/core/service/firebase_service.dart';
import 'package:keep_link/features/friend/application/model/shared_category_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

class SharedCategoryController extends GetxController {
  // ── Static cache (tồn tại qua nhiều lần tạo lại controller) ───────────────
  static bool _needsRefresh = true;
  static List<SharedCategoryModel> _cachedList = [];
  static Set<String> _cachedAccessKeys = {};

  /// Gọi từ FriendController khi phát hiện dữ liệu thay đổi.
  /// Lần vào trang tiếp theo sẽ fetch lại API.
  static void invalidateCache() => _needsRefresh = true;

  /// Xoá cache khi đăng xuất.
  static void clearCache() {
    _needsRefresh = true;
    _cachedList = [];
    _cachedAccessKeys = {};
  }

  // ── Instance state ────────────────────────────────────────────────────────
  final RxList<SharedCategoryModel> sharedCategories = <SharedCategoryModel>[].obs;
  final RxBool isLoading = false.obs;

  /// Keys ("ownerUid/catId") chưa được user mở xem chi tiết
  final RxSet<String> unviewedKeys = <String>{}.obs;

  // State for the currently open shared category detail (links view)
  final RxList<LinkModel> sharedLinks = <LinkModel>[].obs;
  final RxBool isLoadingLinks = false.obs;
  SharedCategoryModel? activeSharedCategory;

  StreamSubscription<List<Map<String, dynamic>>>? _linksSubscription;

  @override
  void onInit() {
    super.onInit();
    if (!_needsRefresh && _cachedList.isNotEmpty) {
      // Cache còn hiệu lực → hiển thị ngay, không gọi API
      sharedCategories.assignAll(_cachedList);
      _restoreUnviewedKeys();
    } else {
      loadSharedCategories();
    }
  }

  @override
  void onClose() {
    _linksSubscription?.cancel();
    super.onClose();
  }

  // ── Unviewed keys ─────────────────────────────────────────────────────────

  void _restoreUnviewedKeys() {
    final uid = FirebaseService.currentUser?.uid;
    if (uid == null) return;
    final viewed = AppGetStorage.getViewedSharedItemKeys(uid);
    unviewedKeys.assignAll(_cachedAccessKeys.difference(viewed));
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadSharedCategories() async {
    if (FirebaseService.currentUser == null) return;

    try {
      isLoading.value = true;
      // Tạo mutable copy để tránh UnsupportedError khi sort trên const []
      final list = List<SharedCategoryModel>.from(
        await FirebaseService.getSharedCategoriesFromFriends(),
      );

      // Sắp xếp theo thời gian nhận share gần nhất (mới nhất lên trên)
      list.sort((a, b) {
        final ta = a.sharedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.sharedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });

      // Cập nhật static cache
      _cachedList = List.from(list);
      _cachedAccessKeys = list.map((c) => '${c.ownerUid}/${c.categoryId}').toSet();
      _needsRefresh = false;

      sharedCategories.assignAll(list);
      _restoreUnviewedKeys();
    } catch (e) {
      debugPrint('Load shared categories error: $e');
      Fluttertoast.showToast(msg: 'shared_load_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Mark viewed ───────────────────────────────────────────────────────────

  void markCategoryViewed(SharedCategoryModel category) {
    final key = '${category.ownerUid}/${category.categoryId}';
    if (!unviewedKeys.contains(key)) return;
    unviewedKeys.remove(key);
    _persistViewedKeys();
  }

  void _persistViewedKeys() {
    final uid = FirebaseService.currentUser?.uid;
    if (uid == null) return;
    final viewed = _cachedAccessKeys.difference(unviewedKeys);
    AppGetStorage.setViewedSharedItemKeys(uid, viewed);
  }

  // ── Open / close category links ───────────────────────────────────────────

  void openSharedCategory(SharedCategoryModel category) {
    activeSharedCategory = category;
    sharedLinks.clear();
    isLoadingLinks.value = true;

    _linksSubscription?.cancel();

    _linksSubscription =
        FirebaseService.watchSharedCategoryLinks(
          ownerUid: category.ownerUid,
          categoryId: category.categoryId,
        ).listen(
          (rawLinks) {
            final links = rawLinks
                .map((json) => LinkModel.fromJson(json, id: json['id'] as String? ?? ''))
                .toList();
            sharedLinks.assignAll(links);
            isLoadingLinks.value = false;

            final idx = sharedCategories.indexWhere(
              (c) => c.ownerUid == category.ownerUid && c.categoryId == category.categoryId,
            );
            if (idx != -1) {
              final updated = sharedCategories[idx].copyWithLinkCount(links.length);
              sharedCategories[idx] = updated;
            }
          },
          onError: (Object e) {
            debugPrint('Watch shared category links error: $e');
            isLoadingLinks.value = false;
            Fluttertoast.showToast(msg: 'shared_load_error'.tr);
          },
        );
  }

  /// Đóng watcher links khi bottom sheet bị đóng
  void closeSharedCategory() {
    _linksSubscription?.cancel();
    _linksSubscription = null;
    activeSharedCategory = null;
    sharedLinks.clear();
  }
}
