import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/data/repositories/link_repository.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/features/friend/application/model/shared_category_model.dart';
import 'package:keep_link/features/friend/application/model/shared_individual_link_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

class SharedCategoryController extends GetxController {
  // ── Static cache ───────────────────────────────────────────────────────────
  static bool _needsRefresh = true;
  static List<SharedCategoryModel> _cachedList = [];
  static List<SharedIndividualLinkModel> _cachedLinksList = [];
  static Set<String> _cachedAccessKeys = {};

  /// Gọi từ FriendController khi phát hiện dữ liệu thay đổi.
  static void invalidateCache() => _needsRefresh = true;

  /// Xoá cache khi đăng xuất.
  static void clearCache() {
    _needsRefresh = true;
    _cachedList = [];
    _cachedLinksList = [];
    _cachedAccessKeys = {};
  }

  // ── Instance state ────────────────────────────────────────────────────────
  final RxList<SharedCategoryModel> sharedCategories = <SharedCategoryModel>[].obs;
  final RxList<SharedIndividualLinkModel> sharedIndividualLinks = <SharedIndividualLinkModel>[].obs;
  final RxBool isLoading = false.obs;
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

  @override
  void onInit() {
    super.onInit();
    if (!_needsRefresh && (_cachedList.isNotEmpty || _cachedLinksList.isNotEmpty)) {
      sharedCategories.assignAll(_cachedList);
      sharedIndividualLinks.assignAll(_cachedLinksList);
      _restoreUnviewedKeys();
    } else {
      loadAllSharedData();
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

  Future<void> loadSharedCategories() async => loadAllSharedData();

  Future<void> loadAllSharedData() async {
    if (FirebaseService.currentUser == null) return;

    try {
      isLoading.value = true;

      final results = await Future.wait([
        FirebaseService.getSharedCategoriesFromFriends(),
        FirebaseService.getSharedIndividualLinksFromFriends(),
      ]);

      final catList = List<SharedCategoryModel>.from(results[0] as List<SharedCategoryModel>);
      final linkList = List<SharedIndividualLinkModel>.from(results[1] as List<SharedIndividualLinkModel>);

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

      sharedCategories.assignAll(catList);
      sharedIndividualLinks.assignAll(linkList);
      _restoreUnviewedKeys();
    } catch (e) {
      debugPrint('Load shared data error: $e');
      Fluttertoast.showToast(msg: 'shared_load_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Save Shared Link To My Collection ─────────────────────────────────────

  Future<void> saveSharedLinkToMyCollection(SharedIndividualLinkModel item) async {
    try {
      final newLink = LinkModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: item.link.name,
        image: item.link.image,
        metaDataModel: item.link.metaDataModel,
        categoryId: 'default',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await LinkRepository.insert(newLink);
      AppToast.showToast('link_saved_to_collection'.tr, Icons.bookmark_added_rounded, color: Colors.green);
    } catch (e) {
      debugPrint('Save shared link error: $e');
      AppToast.showToast('link_save_failed'.tr, Icons.error_outline_rounded, color: Colors.red);
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

    _linksSubscription = FirebaseService.watchSharedCategoryLinks(
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
