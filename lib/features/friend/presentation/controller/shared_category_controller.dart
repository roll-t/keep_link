import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/features/friend/application/model/shared_category_model.dart';
import 'package:keep_link/features/friend/application/model/shared_individual_link_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

class SharedCategoryController extends GetxController {
  // ── Static cache ───────────────────────────────────────────────────────────
  static bool _needsRefresh = true;
  static List<SharedCategoryModel> _cachedList = [];
  static List<SharedIndividualLinkModel> _cachedLinksList = [];
  static Set<String> _cachedAccessKeys = {};
  static String? _cachedUserId;
  static DateTime? _lastFetchedAt;
  static const Duration _cacheTtl = Duration(minutes: 2);

  /// Gọi từ FriendController khi phát hiện dữ liệu thay đổi.
  static void invalidateCache() => _needsRefresh = true;

  /// Xoá cache khi đăng xuất.
  static void clearCache() {
    _needsRefresh = true;
    _cachedList = [];
    _cachedLinksList = [];
    _cachedAccessKeys = {};
    _cachedUserId = null;
    _lastFetchedAt = null;
  }

  // ── Instance state ────────────────────────────────────────────────────────
  final RxList<SharedCategoryModel> sharedCategories =
      <SharedCategoryModel>[].obs;
  final RxList<SharedIndividualLinkModel> sharedIndividualLinks =
      <SharedIndividualLinkModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxnString errorMessage = RxnString();
  final RxString searchQuery = ''.obs;
  final RxInt selectedTab = 0.obs; // 0: Categories, 1: Individual Links

  List<SharedCategoryModel> get visibleCategories {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return sharedCategories;
    return sharedCategories.where((cat) {
      return cat.categoryName.toLowerCase().contains(query) ||
          cat.ownerDisplayName.toLowerCase().contains(query) ||
          (cat.categoryDescription?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<SharedIndividualLinkModel> get visibleIndividualLinks {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return sharedIndividualLinks;
    return sharedIndividualLinks.where((item) {
      final name = item.link.name ?? item.link.metaDataModel?.title ?? '';
      final host = item.link.metaDataModel?.url ?? '';
      return name.toLowerCase().contains(query) ||
          item.ownerDisplayName.toLowerCase().contains(query) ||
          host.toLowerCase().contains(query);
    }).toList();
  }

  /// Keys ("ownerUid/catId" hoặc "ownerUid/linkId") chưa được user mở xem
  final RxSet<String> unviewedKeys = <String>{}.obs;

  // State for the currently open shared category detail (links view)
  final RxList<LinkModel> sharedLinks = <LinkModel>[].obs;
  final RxBool isLoadingLinks = false.obs;
  SharedCategoryModel? activeSharedCategory;

  StreamSubscription<List<Map<String, dynamic>>>? _linksSubscription;
  Future<void>? _loadFuture;

  @override
  void onInit() {
    super.onInit();
    final uid = FirebaseService.currentUser?.uid;
    if (_cachedUserId != uid) {
      clearCache();
      _cachedUserId = uid;
      // Do not keep shared items from the previous account visible while the
      // new account's data is loading.
      sharedCategories.clear();
      sharedIndividualLinks.clear();
      unviewedKeys.clear();
    }
    // Chỉ hydrate cache ở đây. Controller này sống từ màn Home, vì vậy tải
    // Firebase ngay trong onInit sẽ lãng phí reads nếu user không mở trang.
    if (!_needsRefresh) {
      sharedCategories.assignAll(_cachedList);
      sharedIndividualLinks.assignAll(_cachedLinksList);
      _restoreUnviewedKeys();
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

  // ── Load All Shared Data ──────────────────────────────────────────────────

  Future<void> loadSharedCategories({bool force = false}) =>
      loadAllSharedData(force: force);

  Future<void> loadAllSharedData({bool force = false}) async {
    final uid = FirebaseService.currentUser?.uid;
    if (uid == null) {
      sharedCategories.clear();
      sharedIndividualLinks.clear();
      errorMessage.value = null;
      return;
    }

    if (_cachedUserId != uid) {
      clearCache();
      _cachedUserId = uid;
      sharedCategories.clear();
      sharedIndividualLinks.clear();
      unviewedKeys.clear();
    }

    final cacheIsFresh =
        _lastFetchedAt != null &&
        DateTime.now().difference(_lastFetchedAt!) < _cacheTtl;
    if (!force && !_needsRefresh && cacheIsFresh) {
      sharedCategories.assignAll(_cachedList);
      sharedIndividualLinks.assignAll(_cachedLinksList);
      _restoreUnviewedKeys();
      return;
    }

    final pending = _loadFuture;
    if (pending != null) return pending;

    final load = _performLoad();
    _loadFuture = load;
    try {
      await load;
    } finally {
      if (identical(_loadFuture, load)) _loadFuture = null;
    }
  }

  Future<void> _performLoad() async {
    final hasContent =
        sharedCategories.isNotEmpty || sharedIndividualLinks.isNotEmpty;

    try {
      errorMessage.value = null;
      if (hasContent) {
        isRefreshing.value = true;
      } else {
        isLoading.value = true;
      }

      final results = await Future.wait([
        FirebaseService.getSharedCategoriesFromFriends(),
        FirebaseService.getSharedIndividualLinksFromFriends(),
      ]);

      final catList = List<SharedCategoryModel>.from(
        results[0] as List<SharedCategoryModel>,
      );
      final linkList = List<SharedIndividualLinkModel>.from(
        results[1] as List<SharedIndividualLinkModel>,
      );

      catList.sort((a, b) {
        final ta = a.sharedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.sharedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });

      linkList.sort((a, b) {
        final ta = a.sharedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.sharedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });

      _cachedList = List.from(catList);
      _cachedLinksList = List.from(linkList);
      _cachedAccessKeys = {
        ...catList.map((c) => '${c.ownerUid}/${c.categoryId}'),
        ...linkList.map((l) => '${l.ownerUid}/${l.linkId}'),
      };
      _needsRefresh = false;
      _lastFetchedAt = DateTime.now();

      sharedCategories.assignAll(catList);
      sharedIndividualLinks.assignAll(linkList);
      _restoreUnviewedKeys();
    } catch (e) {
      debugPrint('Load shared data error: $e');
      errorMessage.value = 'shared_load_error'.tr;
      if (hasContent) Fluttertoast.showToast(msg: 'shared_load_error'.tr);
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  // ── Mark viewed ───────────────────────────────────────────────────────────

  void markCategoryViewed(SharedCategoryModel category) {
    final key = '${category.ownerUid}/${category.categoryId}';
    unviewedKeys.remove(key);
    final uid = FirebaseService.currentUser?.uid;
    if (uid != null) {
      AppGetStorage.addViewedSharedItemKey(uid, key);
    }
  }

  void markLinkViewed(SharedIndividualLinkModel item) {
    final key = '${item.ownerUid}/${item.linkId}';
    unviewedKeys.remove(key);
    final uid = FirebaseService.currentUser?.uid;
    if (uid != null) {
      AppGetStorage.addViewedSharedItemKey(uid, key);
    }
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
                .map(
                  (json) =>
                      LinkModel.fromJson(json, id: json['id'] as String? ?? ''),
                )
                .toList();
            sharedLinks.assignAll(links);
            isLoadingLinks.value = false;

            final idx = sharedCategories.indexWhere(
              (c) =>
                  c.ownerUid == category.ownerUid &&
                  c.categoryId == category.categoryId,
            );
            if (idx != -1) {
              final updated = sharedCategories[idx].copyWithLinkCount(
                links.length,
              );
              sharedCategories[idx] = updated;
              final cacheIndex = _cachedList.indexWhere(
                (c) =>
                    c.ownerUid == category.ownerUid &&
                    c.categoryId == category.categoryId,
              );
              if (cacheIndex != -1) _cachedList[cacheIndex] = updated;
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
