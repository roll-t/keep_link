import 'package:get/get.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

/// Central in-memory reactive cache — single source of truth.
///
/// Strategy: **write-through**
/// • Reads always come from memory (instant).
/// • Writes hit SQLite first, then update the cache in-place.
/// • DB is loaded into cache once; subsequent reads bypass I/O entirely.
class AppCache {
  AppCache._();

  // ── Links ─────────────────────────────────────────────────────────────────

  static final RxList<LinkModel> links = <LinkModel>[].obs;
  static bool _linksLoaded = false;

  static bool get linksLoaded => _linksLoaded;

  /// Replace entire link cache (called once on first DB load).
  static void setLinks(List<LinkModel> data) {
    links.assignAll(data);
    _linksLoaded = true;
  }

  /// Prepend a newly created link (newest-first order).
  static void addLink(LinkModel link) => links.insert(0, link);

  /// In-place update — O(n) but list is small enough that it is fine.
  static void updateLink(LinkModel updated) {
    final i = links.indexWhere((l) => l.id == updated.id);
    if (i != -1) links[i] = updated;
  }

  static void removeLink(String id) => links.removeWhere((l) => l.id == id);

  // ── Categories ────────────────────────────────────────────────────────────

  static final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  static bool _categoriesLoaded = false;

  static bool get categoriesLoaded => _categoriesLoaded;

  /// Replace entire category cache (called once on first DB load).
  static void setCategories(List<CategoryModel> data) {
    categories.assignAll(data);
    _categoriesLoaded = true;
  }

  /// Prepend a newly created category (newest-first order).
  static void addCategory(CategoryModel cat) => categories.insert(0, cat);

  static void updateCategory(CategoryModel updated) {
    final i = categories.indexWhere((c) => c.id == updated.id);
    if (i != -1) categories[i] = updated;
  }

  static void removeCategory(String id) => categories.removeWhere((c) => c.id == id);

  // ── Derived helpers ───────────────────────────────────────────────────────

  /// IDs of categories whose visibility is not public.
  /// Computed directly from the in-memory list — no DB query needed.
  static Set<String> get privateCategoryIds {
    return categories
        .where((c) => c.visibility != VisibilityStatus.public)
        .map((c) => c.id ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  // ── Cache lifecycle ───────────────────────────────────────────────────────

  /// Wipe everything (call after DB reset or logout).
  static void invalidateAll() {
    links.clear();
    _linksLoaded = false;
    categories.clear();
    _categoriesLoaded = false;
  }

  /// Wipe only the link cache (e.g. after security settings change).
  static void invalidateLinks() {
    links.clear();
    _linksLoaded = false;
  }
}
