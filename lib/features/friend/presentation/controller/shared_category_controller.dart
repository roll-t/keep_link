import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/service/firebase_service.dart';
import 'package:keep_link/features/friend/application/model/shared_category_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

class SharedCategoryController extends GetxController {
  final RxList<SharedCategoryModel> sharedCategories = <SharedCategoryModel>[].obs;
  final RxBool isLoading = false.obs;

  // State for the currently open shared category detail (links view)
  final RxList<LinkModel> sharedLinks = <LinkModel>[].obs;
  final RxBool isLoadingLinks = false.obs;
  SharedCategoryModel? activeSharedCategory;

  StreamSubscription<List<Map<String, dynamic>>>? _linksSubscription;

  @override
  void onInit() {
    super.onInit();
    loadSharedCategories();
  }

  @override
  void onClose() {
    _linksSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadSharedCategories() async {
    if (FirebaseService.currentUser == null) return;

    try {
      isLoading.value = true;
      final list = await FirebaseService.getSharedCategoriesFromFriends();
      sharedCategories.assignAll(list);
    } catch (e) {
      debugPrint('Load shared categories error: $e');
      Fluttertoast.showToast(msg: 'shared_load_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void openSharedCategory(SharedCategoryModel category) {
    activeSharedCategory = category;
    sharedLinks.clear();
    isLoadingLinks.value = true;

    // Huỷ watcher cũ nếu đang mở danh mục khác
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

            // Cập nhật link count trong danh sách category card
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
