import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/cache/sql_lite.dart';
import 'package:keep_link/core/services/backend/session_sync_service.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

/// Data-access layer for [LinkModel].
///
/// All reads are served from [AppCache] (in-memory).
/// All writes go to SQLite first, then update the cache in-place.
class LinkRepository {
  LinkRepository._();

  static const String _table = 'links';

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  /// Loads all links from SQLite into [AppCache] exactly **once**.
  /// Subsequent calls return immediately without touching the DB.
  static Future<void> ensureLoaded() async {
    if (AppCache.linksLoaded) return;

    final rows = await DbHelper.getAll(_table, orderByColumn: 'createdAt', descending: true);
    final list = rows.map((r) => LinkModel.fromJson(Map<String, dynamic>.from(r))).toList();
    AppCache.setLinks(list);
  }

  // ── Reads (in-memory, no I/O) ─────────────────────────────────────────────

  /// Returns every link after applying privacy + category filters.
  ///
  /// The source list is [AppCache.links] which is already sorted
  /// newest-first, so no extra sorting is needed here.
  ///
  /// Callers that page through this (e.g. an infinite-scroll list) should
  /// compute it once per filter change and slice pages out of the result
  /// themselves, rather than calling this again for every page — it's an
  /// O(N) scan over every link, so calling it once per page turns scrolling
  /// through the whole list into an O(N²) scan.
  static List<LinkModel> getFiltered({
    String? categoryId,
    Set<String> privateCategoryIds = const {},
    bool excludePrivate = false,
  }) {
    return AppCache.links.where((link) {
      // Privacy filter — skip links that belong to private categories.
      if (excludePrivate &&
          link.categoryId != null &&
          privateCategoryIds.contains(link.categoryId)) {
        return false;
      }
      // Category filter.
      if (categoryId != null && categoryId != 'all') {
        return link.categoryId == categoryId;
      }
      return true;
    }).toList();
  }

  // ── Writes (write-through) ────────────────────────────────────────────────

  /// Insert a new link.  Writes to DB then prepends to cache.
  static Future<void> insert(LinkModel link) async {
    await DbHelper.upsert(link);
    AppCache.addLink(link);
    SessionSyncService.instance.trackLinkUpsert(link);
    SessionSyncService.instance.pushNow();
  }

  /// Update an existing link.  Writes to DB then updates cache in-place.
  static Future<void> update(LinkModel link) async {
    await DbHelper.update(_table, link.id, link.toJson());
    AppCache.updateLink(link);
    SessionSyncService.instance.trackLinkUpsert(link);
    SessionSyncService.instance.pushNow();
  }

  /// Delete a link by id.  Removes from DB then from cache.
  static Future<void> delete(String id) async {
    await DbHelper.delete(_table, id);
    AppCache.removeLink(id);
    SessionSyncService.instance.trackLinkDelete(id);
    SessionSyncService.instance.pushNow();
  }
}
