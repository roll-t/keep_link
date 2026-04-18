import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/cache/app_cache.dart';
import 'package:keep_link/core/cache/app_get_storage.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/repository/category_repository.dart';
import 'package:keep_link/core/repository/link_repository.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

enum SortOption { newest, oldest, nameAZ, nameZA }

class SearchLinkController extends GetxController {
  // ── State ──────────────────────────────────────────────────────────────────
  final searchTec = TextEditingController();
  final searchText = ''.obs;
  final searchResults = <LinkModel>[].obs;

  /// True only during the initial DB → cache load (first ever open).
  /// Subsequent opens are instant since the cache is already warm.
  final isLoading = false.obs;

  late final bool isSecurityEnabled;

  // Category
  final categories = <CategoryModel>[].obs;
  final selectedCategoryId = Rx<String?>(null);

  // Sort
  final selectedSort = SortOption.newest.obs;

  final categoryScrollController = ScrollController();

  // Private category IDs — computed from AppCache, no DB query.
  Set<String> _privateCategoryIds = {};

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    isSecurityEnabled = AppGetStorage.isCategorySecurity();

    searchTec.addListener(() {
      searchText.value = searchTec.text;
      if (searchTec.text.isEmpty) _filterAndShow();
    });

    // debounce still gives a smooth UX even though the work is now synchronous.
    debounce(searchText, (_) => _runSearch(), time: const Duration(milliseconds: 300));

    ever(selectedCategoryId, (_) => _runSearch());
    ever(selectedSort, (_) => _runSearch());

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
    // Both calls are no-ops if the cache is already warm (typical after the
    // first screen load).  Only the very first open hits SQLite.
    isLoading.value = true;
    try {
      await Future.wait([CategoryRepository.ensureLoaded(), LinkRepository.ensureLoaded()]);
      _computePrivateCategoryIds();
      _populateCategoryList();
      _filterAndShow();
    } catch (e) {
      log('SearchLinkController init error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Compute helpers (in-memory, no I/O) ───────────────────────────────────

  void _computePrivateCategoryIds() {
    _privateCategoryIds = isSecurityEnabled ? AppCache.privateCategoryIds : const {};
    log('Private category IDs: ${_privateCategoryIds.length}');
  }

  void _populateCategoryList() {
    final list = isSecurityEnabled
        ? AppCache.categories.where((c) => c.visibility == VisibilityStatus.public).toList()
        : List<CategoryModel>.from(AppCache.categories);
    categories.assignAll(list);
  }

  // ── Filter / Search (pure in-memory — no DB query) ────────────────────────

  void _filterAndShow() {
    final all = AppCache.links.where(_passPrivacyFilter).where(_passCategoryFilter).toList();
    searchResults.assignAll(_applySorting(all));
  }

  void _runSearch() {
    final query = searchText.value.trim();
    if (query.isEmpty) {
      _filterAndShow();
      return;
    }

    final searchKey = Utils.removeDiacritics(query).toLowerCase();
    final filtered = AppCache.links
        .where(_passPrivacyFilter)
        .where(_passCategoryFilter)
        .where((item) => _matchSearch(item, searchKey))
        .toList();

    searchResults.assignAll(_applySorting(filtered));
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
