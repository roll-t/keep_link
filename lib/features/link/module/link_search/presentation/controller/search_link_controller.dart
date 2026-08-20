import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/data/repositories/category_repository.dart';
import 'package:keep_link/core/data/repositories/link_repository.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

enum SortOption { newest, oldest, nameAZ, nameZA }

/// Thống kê số lượng link theo nguồn (domain).
class SourceStat {
  final String host; // normalized key, e.g. "tiktok.com"
  final String label; // display name, e.g. "TikTok"
  final int count;
  const SourceStat({required this.host, required this.label, required this.count});
}

class SearchLinkController extends GetxController {
  // ── State ──────────────────────────────────────────────────────────────────
  final searchTec = TextEditingController();
  final searchFocusNode = FocusNode();
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

  // Source
  final topSources = <SourceStat>[].obs;
  final selectedSource = Rx<String?>(null);

  // Date range
  final dateFrom = Rx<DateTime?>(null);
  final dateTo = Rx<DateTime?>(null);

  final categoryScrollController = ScrollController();

  // Search history & suggestions
  final searchHistory = <String>[].obs;
  final suggestions = <String>[].obs;
  final isFieldFocused = false.obs;

  // Private category IDs — computed from AppCache, no DB query.
  Set<String> _privateCategoryIds = {};

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    isSecurityEnabled = AppGetStorage.isCategorySecurity();

    // Load search history from storage
    searchHistory.assignAll(AppGetStorage.getSearchHistory());

    searchFocusNode.addListener(() {
      if (searchFocusNode.hasFocus) {
        isFieldFocused.value = true;
      } else {
        // Delay 150ms so suggestion/history tile tap gesture (pointer up) completes
        // before the panel is removed from the widget tree.
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!searchFocusNode.hasFocus) {
            isFieldFocused.value = false;
          }
        });
      }
    });

    searchTec.addListener(() {
      searchText.value = searchTec.text;
      if (searchTec.text.isEmpty) _filterAndShow();
    });

    debounce(searchText, (q) {
      _runSearch();
      _computeSuggestions(q);
    }, time: const Duration(milliseconds: 300));

    ever(selectedCategoryId, (_) => _runSearch());
    ever(selectedSort, (_) => _runSearch());
    ever(selectedSource, (_) => _runSearch());
    ever(dateFrom, (_) => _runSearch());
    ever(dateTo, (_) => _runSearch());

    // Recompute category link-counts whenever the link cache changes
    // (covers add, update/move, delete).
    ever(AppCache.links, (_) => _recomputeChildrenCounts());

    _init();
  }

  @override
  void onClose() {
    searchTec.dispose();
    searchFocusNode.dispose();
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
      _computeTopSources();
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
    _recomputeChildrenCounts();
  }

  /// Counts links per category from [AppCache.links] and refreshes the
  /// [categories] list so the chip labels update reactively.
  void _recomputeChildrenCounts() {
    final counts = <String, int>{};
    for (final link in AppCache.links) {
      final cid = link.categoryId;
      if (cid == null || cid.isEmpty) continue;
      if (_privateCategoryIds.contains(cid)) continue;
      counts[cid] = (counts[cid] ?? 0) + 1;
    }
    for (final cat in categories) {
      cat.chilrenCount = counts[cat.id] ?? 0;
    }
    categories.refresh();
  }

  // ── Filter / Search (pure in-memory — no DB query) ────────────────────────

  void _filterAndShow() {
    final all = AppCache.links
        .where(_passPrivacyFilter)
        .where(_passCategoryFilter)
        .where(_passSourceFilter)
        .where(_passDateFilter)
        .toList();
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
        .where(_passSourceFilter)
        .where(_passDateFilter)
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

  bool _passSourceFilter(LinkModel item) {
    if (selectedSource.value == null) return true;
    return _normalizeHost(item.metaDataModel?.url) == selectedSource.value;
  }

  bool _passDateFilter(LinkModel item) {
    final d = item.createdAt;
    if (d == null) return true;
    final from = dateFrom.value;
    final to = dateTo.value;
    if (from != null && d.isBefore(from)) return false;
    // include the entire "to" day
    if (to != null && d.isAfter(DateTime(to.year, to.month, to.day, 23, 59, 59))) return false;
    return true;
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
  void selectSource(String? host) => selectedSource.value = host;
  void selectDateRange(DateTime? from, DateTime? to) {
    dateFrom.value = from;
    dateTo.value = to;
  }

  void clearSearch() {
    searchTec.clear();
    searchResults.clear();
  }

  // ── History / Suggestions ──────────────────────────────────────────────────

  void _computeSuggestions(String query) {
    if (query.trim().isEmpty) {
      suggestions.clear();
      return;
    }
    final key = Utils.removeDiacritics(query.trim()).toLowerCase();
    final seen = <String>{};
    final result = <String>[];
    for (final link in AppCache.links) {
      if (_privateCategoryIds.contains(link.categoryId)) continue;
      for (final text in [link.name ?? '', link.metaDataModel?.title ?? '']) {
        if (text.isEmpty) continue;
        final normalized = Utils.removeDiacritics(text).toLowerCase();
        if (normalized.contains(key) && seen.add(text)) {
          result.add(text);
          if (result.length >= 6) break;
        }
      }
      if (result.length >= 6) break;
    }
    suggestions.assignAll(result);
  }

  void _saveToHistory(String query) {
    final q = query.trim();
    if (q.isEmpty || q.length < 2) return;
    final list = List<String>.from(searchHistory);
    list.remove(q);
    list.insert(0, q);
    if (list.length > AppGetStorage.maxSearchHistory) list.removeLast();
    searchHistory.assignAll(list);
    AppGetStorage.saveSearchHistory(list);
  }

  void removeFromHistory(String query) {
    searchHistory.remove(query);
    AppGetStorage.saveSearchHistory(List<String>.from(searchHistory));
  }

  void clearAllHistory() {
    searchHistory.clear();
    AppGetStorage.clearSearchHistory();
  }

  /// Tap on a suggestion or history item — fill field + run search + save.
  void applyQuery(String text) {
    searchTec.value = TextEditingValue(
      text: text,
      selection: TextSelection.fromPosition(TextPosition(offset: text.length)),
    );
    searchText.value = text;
    _saveToHistory(text);
    _runSearch();
    suggestions.clear();
    isFieldFocused.value = false;
    searchFocusNode.unfocus();
  }

  // ── Source helpers ─────────────────────────────────────────────────────────

  /// Normalises a URL to a canonical host key (e.g. "vm.tiktok.com" → "tiktok.com").
  static String _normalizeHost(String? url) {
    if (url == null || url.isEmpty) return '';
    try {
      final h = Uri.parse(url).host.toLowerCase().replaceFirst('www.', '');
      if (h.contains('tiktok.com')) return 'tiktok.com';
      if (h.contains('youtu.be') || h.contains('youtube.com')) return 'youtube.com';
      if (h.contains('instagram.com')) return 'instagram.com';
      if (h.contains('facebook.com') || h.contains('fb.com') || h.contains('fb.watch')) {
        return 'facebook.com';
      }
      if (h.contains('twitter.com') || h.contains('x.com')) return 'x.com';
      if (h.contains('google.com')) return 'google.com';
      return h;
    } catch (_) {
      return '';
    }
  }

  static String _labelForHost(String host) {
    const labels = {
      'tiktok.com': 'TikTok',
      'youtube.com': 'YouTube',
      'instagram.com': 'Instagram',
      'facebook.com': 'Facebook',
      'x.com': 'X',
      'google.com': 'Google',
    };
    return labels[host] ?? host;
  }

  void _computeTopSources() {
    final counter = <String, int>{};
    for (final link in AppCache.links) {
      if (_privateCategoryIds.contains(link.categoryId)) continue;
      final host = _normalizeHost(link.metaDataModel?.url);
      if (host.isEmpty) continue;
      counter[host] = (counter[host] ?? 0) + 1;
    }
    final sorted = counter.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    topSources.assignAll(
      sorted
          .take(5)
          .map((e) => SourceStat(host: e.key, label: _labelForHost(e.key), count: e.value)),
    );
  }
}
