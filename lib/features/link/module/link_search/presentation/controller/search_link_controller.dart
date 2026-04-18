import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';
import 'package:keep_link/core/local_storage/sql_lite.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

enum SortOption { newest, oldest, nameAZ, nameZA }

class SearchLinkController extends GetxController {
  // ── State ──────────────────────────────────────────────────────────────────
  final searchTec = TextEditingController();
  final searchText = ''.obs;
  final searchResults = <LinkModel>[].obs;
  final isLoading = false.obs;
  late final bool isSecurityEnabled;
  // Category
  final categories = <CategoryModel>[].obs;
  final selectedCategoryId = Rx<String?>(null);

  // Sort
  final selectedSort = SortOption.newest.obs;

  final categoryScrollController = ScrollController();

  // Cache private IDs — tránh query lại mỗi lần search
  Set<String> _privateCategoryIds = {};

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    isSecurityEnabled = AppGetStorage.isCategorySecurity();
    searchTec.addListener(() {
      searchText.value = searchTec.text;
      if (searchTec.text.isEmpty) _showAllLinks();
    });

    debounce(searchText, (_) => _runSearch(), time: const Duration(milliseconds: 400));

    ever(selectedCategoryId, (_) => _runSearch());
    ever(selectedSort, (_) => _runSearch());

    // Load dữ liệu ban đầu
    _init();
  }

  @override
  void onClose() {
    searchTec.dispose();
    categoryScrollController.dispose();
    super.onClose();
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    await Future.wait([_loadPrivateCategoryIds(), _loadCategories()]);
    await _showAllLinks();
  }

  Future<void> _loadPrivateCategoryIds() async {
    try {
      // Kiểm tra trạng thái bảo mật từ Storage

      if (isSecurityEnabled) {
        final rows = await DbHelper.getAll('categories');
        _privateCategoryIds = rows
            .map((r) => CategoryModel.fromJson(Map<String, dynamic>.from(r)))
            // Lấy những category KHÔNG phải Public
            .where((c) => c.visibility != VisibilityStatus.public)
            .map((c) => c.id ?? '')
            .toSet();
      } else {
        _privateCategoryIds = {};
      }

      log('Đã cập nhật danh sách ID riêng tư: ${_privateCategoryIds.length} mục');
    } catch (e) {
      log('Lỗi load private categories: $e');
      _privateCategoryIds = {}; // Tránh lỗi null khi search
    }
  }

  Future<void> _loadCategories() async {
    try {
      final rows = await DbHelper.getAll('categories');
      final isCategorySecurityEnabled = AppGetStorage.isCategorySecurity();
      if (isCategorySecurityEnabled) {
        final list = rows
            .map((r) => CategoryModel.fromJson(Map<String, dynamic>.from(r)))
            .where((c) => c.visibility == VisibilityStatus.public)
            .toList();
        categories.assignAll(list);
      } else {
        categories.assignAll(rows.map((r) => CategoryModel.fromJson(Map<String, dynamic>.from(r))));
      }
    } catch (e) {
      log('Lỗi load categories: $e');
    }
  }

  // ── Hiển thị tất cả link khi chưa search ─────────────────────────────────

  Future<void> _showAllLinks() async {
    isLoading.value = true;
    try {
      final rows = await DbHelper.getAll('links');
      final all = rows
          .map((r) => LinkModel.fromJson(Map<String, dynamic>.from(r)))
          .where(_passPrivacyFilter)
          .where(_passCategoryFilter)
          .toList();

      searchResults.assignAll(_applySorting(all));
    } catch (e) {
      log('Lỗi load all links: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  Future<void> _runSearch() async {
    final query = searchText.value.trim();

    // Nếu trống thì show all
    if (query.isEmpty) {
      await _showAllLinks();
      return;
    }

    isLoading.value = true;
    try {
      final rows = await DbHelper.getAll('links');
      final searchKey = Utils.removeDiacritics(query).toLowerCase();

      final filtered = rows
          .map((r) => LinkModel.fromJson(Map<String, dynamic>.from(r)))
          .where(_passPrivacyFilter)
          .where(_passCategoryFilter)
          .where((item) => _matchSearch(item, searchKey))
          .toList();

      searchResults.assignAll(_applySorting(filtered));
    } catch (e) {
      log('Lỗi tìm kiếm: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Filters ────────────────────────────────────────────────────────────────

  bool _passPrivacyFilter(LinkModel item) {
    if (item.categoryId == null) return true;
    return !_privateCategoryIds.contains(item.categoryId);
  }

  bool _passCategoryFilter(LinkModel item) {
    if (selectedCategoryId.value == null) return true;
    return item.categoryId == selectedCategoryId.value;
  }

  bool _matchSearch(LinkModel item, String searchKey) {
    final title = Utils.removeDiacritics(item.metaDataModel?.title ?? '').toLowerCase();
    final note = Utils.removeDiacritics(item.name ?? '').toLowerCase();
    final url = (item.metaDataModel?.url ?? '').toLowerCase();
    return title.contains(searchKey) || note.contains(searchKey) || url.contains(searchKey);
  }

  List<LinkModel> _applySorting(List<LinkModel> list) {
    final sorted = List<LinkModel>.from(list);
    switch (selectedSort.value) {
      case SortOption.newest:
        sorted.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      case SortOption.oldest:
        sorted.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
      case SortOption.nameAZ:
        sorted.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      case SortOption.nameZA:
        sorted.sort((a, b) => (b.name ?? '').compareTo(a.name ?? ''));
    }
    return sorted;
  }

  // ── Public actions ─────────────────────────────────────────────────────────

  void selectCategory(String? id) => selectedCategoryId.value = id;
  void selectSort(SortOption opt) => selectedSort.value = opt;

  void clearSearch() {
    searchTec.clear();
    searchResults.clear();
  }
}
