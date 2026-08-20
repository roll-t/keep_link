import 'package:get/get.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
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

  // ── Friends ───────────────────────────────────────────────────────────────

  static final RxList<FriendModel> friends = <FriendModel>[].obs;
  static bool _friendsLoaded = false;

  static bool get friendsLoaded => _friendsLoaded;

  static void setFriends(List<FriendModel> data) {
    friends.assignAll(data);
    _friendsLoaded = true;
  }

  static void addFriend(FriendModel friend) => friends.insert(0, friend);

  static void updateFriend(FriendModel updated) {
    final i = friends.indexWhere((friend) => friend.id == updated.id);
    if (i != -1) friends[i] = updated;
  }

  static void removeFriend(String id) => friends.removeWhere((friend) => friend.id == id);

  // ── Shared-with cache (categoryId → friends it is shared with) ────────────

  /// Reactive map: key = categoryId, value = list of friends who have access.
  /// Updated locally after every share/unshare — no extra Firebase reads.
  static final RxMap<String, List<FriendModel>> sharedWithCache = <String, List<FriendModel>>{}.obs;

  /// Initialise/replace entries from a bulk fetch (called once on login).
  static void setSharedWith(Map<String, List<FriendModel>> data) {
    sharedWithCache.assignAll(data);
  }

  /// Add a friend to a category's shared list.
  static void addSharedFriend(String categoryId, FriendModel friend) {
    final list = List<FriendModel>.from(sharedWithCache[categoryId] ?? []);
    if (!list.any((f) => f.friendUserId == friend.friendUserId)) {
      list.add(friend);
    }
    sharedWithCache[categoryId] = list;
  }

  /// Remove a friend from a category's shared list.
  static void removeSharedFriend(String categoryId, String friendUserId) {
    final list = List<FriendModel>.from(sharedWithCache[categoryId] ?? []);
    list.removeWhere((f) => f.friendUserId == friendUserId);
    if (list.isEmpty) {
      sharedWithCache.remove(categoryId);
    } else {
      sharedWithCache[categoryId] = list;
    }
  }

  /// Remove a friend from every category in the shared-with cache.
  /// Call this after the friend is deleted so ShareCategorySheet stays in sync.
  static void removeSharedFriendFromAll(String friendUserId) {
    final keysToRemove = <String>[];
    for (final entry in sharedWithCache.entries) {
      final updated = List<FriendModel>.from(entry.value)
        ..removeWhere((f) => f.friendUserId == friendUserId);
      if (updated.isEmpty) {
        keysToRemove.add(entry.key);
      } else {
        sharedWithCache[entry.key] = updated;
      }
    }
    for (final key in keysToRemove) {
      sharedWithCache.remove(key);
    }
  }

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
    friends.clear();
    _friendsLoaded = false;
    sharedWithCache.clear();
  }

  /// Wipe only the link cache (e.g. after security settings change).
  static void invalidateLinks() {
    links.clear();
    _linksLoaded = false;
  }
}
