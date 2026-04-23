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

  @override
  void onInit() {
    super.onInit();
    loadSharedCategories();
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

  Future<void> openSharedCategory(SharedCategoryModel category) async {
    activeSharedCategory = category;
    sharedLinks.clear();

    try {
      isLoadingLinks.value = true;
      final rawLinks = await FirebaseService.fetchSharedCategoryLinks(
        ownerUid: category.ownerUid,
        categoryId: category.categoryId,
      );
      final links = rawLinks
          .map((json) => LinkModel.fromJson(json, id: json['id'] as String? ?? ''))
          .toList();
      sharedLinks.assignAll(links);
    } catch (e) {
      debugPrint('Open shared category error: $e');
      Fluttertoast.showToast(msg: 'shared_load_error'.tr);
    } finally {
      isLoadingLinks.value = false;
    }
  }
}
