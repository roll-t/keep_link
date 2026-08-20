import 'dart:convert';
import 'dart:developer';

import 'package:get_storage/get_storage.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/data/cache/sql_lite.dart';
import 'package:keep_link/core/data/repositories/category_repository.dart';
import 'package:keep_link/core/data/repositories/link_repository.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

/// Collects local mutations during a session.
///
/// Strategy (reliable, network-safe):
/// • During use: mutations accumulate in-memory only.
/// • On app background/close: queue is persisted to GetStorage.
/// • On next app launch: persisted queue is loaded and pushed to Firebase
///   in a single multi-path update (1 request). Storage is cleared on success.
class SessionSyncService {
  SessionSyncService._();

  static final SessionSyncService instance = SessionSyncService._();

  static const _storageKey = 'session_pending_queue';
  static final _box = GetStorage();

  // In-memory queues for the current session.
  final Map<String, Map<String, dynamic>> _pendingLinkUpserts = {};
  final Set<String> _pendingLinkDeletes = {};
  final Map<String, Map<String, dynamic>> _pendingCategoryUpserts = {};
  final Set<String> _pendingCategoryDeletes = {};

  bool _isFlushing = false;

  bool get hasPendingChanges =>
      _pendingLinkUpserts.isNotEmpty ||
      _pendingLinkDeletes.isNotEmpty ||
      _pendingCategoryUpserts.isNotEmpty ||
      _pendingCategoryDeletes.isNotEmpty;

  // ── Track ─────────────────────────────────────────────────────────────────

  void trackLinkUpsert(LinkModel link) {
    _pendingLinkDeletes.remove(link.id);
    _pendingLinkUpserts[link.id] = link.toJson();
  }

  void trackLinkDelete(String linkId) {
    _pendingLinkUpserts.remove(linkId);
    _pendingLinkDeletes.add(linkId);
  }

  void trackCategoryUpsert(CategoryModel category) {
    final id = category.id;
    if (id == null || id.isEmpty) return;
    _pendingCategoryDeletes.remove(id);
    _pendingCategoryUpserts[id] = category.toJson();
  }

  void trackCategoryDelete(String categoryId) {
    _pendingCategoryUpserts.remove(categoryId);
    _pendingCategoryDeletes.add(categoryId);
  }

  // ── Persist (called when app goes to background / closes) ─────────────────

  /// Merges in-memory queue into the existing persisted queue, then clears
  /// the in-memory queue. Safe to call multiple times (e.g. paused + detached).
  void persistQueue() {
    if (!hasPendingChanges) return;

    // Load existing persisted data so we don't overwrite previous pending items
    // that haven't been flushed yet (e.g. user was offline on last launch).
    final existing = _loadStoredQueue();

    // Merge: in-memory wins over persisted (newer data).
    final mergedLinkUpserts = <String, dynamic>{...existing['linkUpserts'] as Map? ?? {}};
    _pendingLinkUpserts.forEach((k, v) => mergedLinkUpserts[k] = v);

    final mergedLinkDeletes = <String>{
      ...List<String>.from(existing['linkDeletes'] as List? ?? []),
      ..._pendingLinkDeletes,
    };
    // A delete cancels any previously persisted upsert for the same id.
    for (final id in mergedLinkDeletes) {
      mergedLinkUpserts.remove(id);
    }

    final mergedCategoryUpserts = <String, dynamic>{...existing['categoryUpserts'] as Map? ?? {}};
    _pendingCategoryUpserts.forEach((k, v) => mergedCategoryUpserts[k] = v);

    final mergedCategoryDeletes = <String>{
      ...List<String>.from(existing['categoryDeletes'] as List? ?? []),
      ..._pendingCategoryDeletes,
    };
    for (final id in mergedCategoryDeletes) {
      mergedCategoryUpserts.remove(id);
    }

    _box.write(
      _storageKey,
      jsonEncode({
        'linkUpserts': mergedLinkUpserts,
        'linkDeletes': mergedLinkDeletes.toList(),
        'categoryUpserts': mergedCategoryUpserts,
        'categoryDeletes': mergedCategoryDeletes.toList(),
      }),
    );

    final total =
        mergedLinkUpserts.length +
        mergedLinkDeletes.length +
        mergedCategoryUpserts.length +
        mergedCategoryDeletes.length;
    log('Session queue persisted: $total paths queued for next launch.');

    // Clear in-memory queue since data is now safely in storage.
    _clearInMemory();
  }

  // ── Flush (called at next app launch, after Firebase is ready) ────────────

  /// Reads the persisted queue and pushes to Firebase in 1 request.
  /// Does nothing if not authenticated or no pending data.
  Future<void> flushPersistedQueue() async {
    if (_isFlushing) return;

    final stored = _loadStoredQueue();
    if (stored.isEmpty) return;

    // Wait for Firebase Auth to fully restore the previous session.
    // Checking currentUser synchronously can return null even when the user
    // was logged in, because the auth state token hasn't been fetched yet.
    final user = await FirebaseService.authStateChanges.first;
    final userId = user?.uid;
    if (userId == null || userId.isEmpty) {
      log('Skip persisted sync: user is not authenticated.');
      return;
    }

    _isFlushing = true;
    try {
      final linkUpserts = Map<String, dynamic>.from(stored['linkUpserts'] as Map? ?? {});
      final linkDeletes = List<String>.from(stored['linkDeletes'] as List? ?? []);
      final categoryUpserts = Map<String, dynamic>.from(stored['categoryUpserts'] as Map? ?? {});
      final categoryDeletes = List<String>.from(stored['categoryDeletes'] as List? ?? []);

      final updates = <String, dynamic>{};
      linkUpserts.forEach((id, data) => updates['links/$id'] = data);
      for (final id in linkDeletes) {
        updates['links/$id'] = null;
      }
      categoryUpserts.forEach((id, data) => updates['categories/$id'] = data);
      for (final id in categoryDeletes) {
        updates['categories/$id'] = null;
      }

      if (updates.isEmpty) {
        _box.remove(_storageKey);
        return;
      }

      await FirebaseService.applyUserDelta(userId, updates);

      _box.remove(_storageKey);
      log(
        'Persisted queue flushed: ${updates.length} paths. '
        'links(upsert=${linkUpserts.length}, delete=${linkDeletes.length}), '
        'categories(upsert=${categoryUpserts.length}, delete=${categoryDeletes.length})',
      );
    } catch (e) {
      // Keep storage intact — will retry on the launch after next.
      log('Persisted queue flush failed (will retry next launch): $e');
    } finally {
      _isFlushing = false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _loadStoredQueue() {
    try {
      final raw = _box.read<String>(_storageKey);
      if (raw == null || raw.isEmpty) return {};
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  void _clearInMemory() {
    _pendingLinkUpserts.clear();
    _pendingLinkDeletes.clear();
    _pendingCategoryUpserts.clear();
    _pendingCategoryDeletes.clear();
  }

  void clearAll() {
    _clearInMemory();
    _box.remove(_storageKey);
  }

  /// Called on sign-out. Clears queue and last-reconcile stamp so the next
  /// sign-in triggers a full push + pull immediately (no 24h throttle).
  void clearOnSignOut() {
    _clearInMemory();
    _box.remove(_storageKey);
    _box.remove(_lastReconciledKey);
  }

  /// Push all in-memory mutations from the current session to Firebase.
  /// Used right before signing out so changes made since the last
  /// background/close are not lost.
  Future<void> flushCurrentSession(String userId) async {
    if (!hasPendingChanges) return;

    final updates = <String, dynamic>{};
    _pendingLinkUpserts.forEach((id, data) => updates['links/$id'] = data);
    for (final id in _pendingLinkDeletes) {
      updates['links/$id'] = null;
    }
    _pendingCategoryUpserts.forEach((id, data) => updates['categories/$id'] = data);
    for (final id in _pendingCategoryDeletes) {
      updates['categories/$id'] = null;
    }

    if (updates.isEmpty) return;

    try {
      await FirebaseService.applyUserDelta(userId, updates);
      log('Pre-signout flush: ${updates.length} paths pushed to Firebase.');
    } catch (e) {
      log('Pre-signout flush failed: $e');
      // Persist so it can be retried on the next launch.
      persistQueue();
    }
  }

  // ── Immediate push (fire-and-forget) ─────────────────────────────────────

  /// Pushes all current in-memory pending changes to Firebase immediately.
  ///
  /// Call this after any user-initiated delete or update so changes are
  /// reflected in Firebase right away instead of waiting for the next
  /// app launch or logout.
  ///
  /// - Does nothing if the user is not authenticated (guest mode).
  /// - Does nothing if there are no pending changes.
  /// - Skips if a flush is already in progress.
  /// - On success, clears the in-memory queue (changes are safe in Firebase).
  /// - On failure, leaves the queue intact so it will be retried via the
  ///   normal persist-on-close → flush-on-launch path.
  void pushNow() {
    final userId = FirebaseService.currentUserId;
    if (userId == null || userId.isEmpty) return;
    if (!hasPendingChanges) return;
    if (_isFlushing) return;

    // Fire-and-forget — caller does not need to await.
    flushCurrentSession(userId).catchError((e) {
      log('pushNow failed (will retry on next launch): $e');
    });
  }

  // ── Post-login sync ───────────────────────────────────────────────────────

  /// Called immediately after a user signs in for the first time in a session.
  ///
  /// Combines two steps in one pass:
  /// 1. Flush all in-memory pending changes + any previously persisted queue.
  /// 2. Reconcile ALL local SQLite records against Firebase (bypasses 24h throttle).
  ///
  /// This ensures links saved while the user was a guest are uploaded right
  /// after login without requiring an app restart.
  Future<void> syncAfterLogin(String userId) async {
    if (userId.isEmpty) return;
    log('Post-login sync started for user $userId.');

    try {
      // Merge in-memory queue with any previously persisted (offline) queue.
      final stored = _loadStoredQueue();

      final linkUpserts = Map<String, dynamic>.from(stored['linkUpserts'] as Map? ?? {});
      _pendingLinkUpserts.forEach((k, v) => linkUpserts[k] = v);

      final linkDeletes = <String>{
        ...List<String>.from(stored['linkDeletes'] as List? ?? []),
        ..._pendingLinkDeletes,
      };
      for (final id in linkDeletes) {
        linkUpserts.remove(id);
      }

      final categoryUpserts = Map<String, dynamic>.from(stored['categoryUpserts'] as Map? ?? {});
      _pendingCategoryUpserts.forEach((k, v) => categoryUpserts[k] = v);

      final categoryDeletes = <String>{
        ...List<String>.from(stored['categoryDeletes'] as List? ?? []),
        ..._pendingCategoryDeletes,
      };
      for (final id in categoryDeletes) {
        categoryUpserts.remove(id);
      }

      // Reconcile: find all local SQLite records that are not already queued
      // and not yet on Firebase.
      await LinkRepository.ensureLoaded();
      await CategoryRepository.ensureLoaded();

      final remoteData = await FirebaseService.getUserData(userId);
      final remoteLinks = Map<String, dynamic>.from(remoteData?['links'] as Map? ?? {});
      final remoteCategories = Map<String, dynamic>.from(remoteData?['categories'] as Map? ?? {});

      // ── Guest-default category guard ──────────────────────────────────────
      // The default "Danh Mục" category is auto-created for guests.
      // • New account (no remote categories) → push it as-is (first-time switch).
      // • Returning/different account (has remote categories) → exclude it from
      //   the push, remap its links to uncategorized, and delete it locally.
      final guestDefaultCatId = AppGetStorage.guestDefaultCategoryId;
      final excludeGuestDefault = guestDefaultCatId != null && remoteCategories.isNotEmpty;

      if (excludeGuestDefault) {
        categoryUpserts.remove(guestDefaultCatId);
        // Remap any links belonging to this category to uncategorized.
        for (final id in linkUpserts.keys.toList()) {
          final data = Map<String, dynamic>.from(linkUpserts[id] as Map);
          if (data['categoryId'] == guestDefaultCatId) {
            data['categoryId'] = null;
            linkUpserts[id] = data;
          }
        }
      }

      for (final link in AppCache.links) {
        if (!linkUpserts.containsKey(link.id) && !remoteLinks.containsKey(link.id)) {
          linkUpserts[link.id] = link.toJson();
        }
      }
      for (final cat in AppCache.categories) {
        final id = cat.id;
        if (id == null || id.isEmpty) continue;
        // Never push the guest default category to an account that already has
        // its own categories.
        if (id == guestDefaultCatId && excludeGuestDefault) continue;
        if (!categoryUpserts.containsKey(id) && !remoteCategories.containsKey(id)) {
          categoryUpserts[id] = cat.toJson();
        }
      }

      // Build one combined update map.
      final updates = <String, dynamic>{};
      linkUpserts.forEach((id, data) => updates['links/$id'] = data);
      for (final id in linkDeletes) {
        updates['links/$id'] = null;
      }
      categoryUpserts.forEach((id, data) => updates['categories/$id'] = data);
      for (final id in categoryDeletes) {
        updates['categories/$id'] = null;
      }

      if (updates.isNotEmpty) {
        await FirebaseService.applyUserDelta(userId, updates);
        log('Post-login sync: pushed ${updates.length} paths to Firebase.');
      } else {
        log('Post-login sync: already in sync.');
      }

      // ── Local cleanup for excluded guest default category ─────────────────
      if (excludeGuestDefault) {
        // Delete the default category from local SQLite.
        await DbHelper.delete(CategoryModel().tableName, guestDefaultCatId);
        // Remap links that belonged to it → uncategorized in local SQLite.
        final affectedLinks = AppCache.links
            .where((l) => l.categoryId == guestDefaultCatId)
            .toList();
        for (final link in affectedLinks) {
          await DbHelper.update(LinkModel(id: '').tableName, link.id, {'categoryId': null});
        }
        log(
          'Guest default category removed locally. '
          'Remapped ${affectedLinks.length} link(s) to uncategorized.',
        );
      }
      // Always clear the guest key — it is no longer needed after login.
      AppGetStorage.clearGuestDefaultCategoryId();

      // ── PULL: download Firebase items that are not in local SQLite ──────────
      final localLinkIds = AppCache.links.map((l) => l.id).toSet();
      final localCategoryIds = AppCache.categories
          .map((c) => c.id)
          .where((id) => id != null && id.isNotEmpty)
          .toSet();

      final categoriesToInsert = <CategoryModel>[];
      for (final entry in remoteCategories.entries) {
        if (!localCategoryIds.contains(entry.key)) {
          try {
            final data = Map<String, dynamic>.from(entry.value as Map)..['id'] = entry.key;
            categoriesToInsert.add(CategoryModel.fromJson(data));
          } catch (e) {
            log('Post-login sync: failed to parse remote category ${entry.key}: $e');
          }
        }
      }

      final linksToInsert = <LinkModel>[];
      for (final entry in remoteLinks.entries) {
        if (!localLinkIds.contains(entry.key)) {
          try {
            final data = Map<String, dynamic>.from(entry.value as Map);
            linksToInsert.add(LinkModel.fromJson(data, id: entry.key));
          } catch (e) {
            log('Post-login sync: failed to parse remote link ${entry.key}: $e');
          }
        }
      }

      // Insert categories first (links reference categories via FK).
      if (categoriesToInsert.isNotEmpty) {
        await DbHelper.upsertAll(categoriesToInsert);
      }

      if (linksToInsert.isNotEmpty) {
        await DbHelper.upsertAll(linksToInsert);
      }

      log(
        'Post-login sync: pulled ${linksToInsert.length} links, '
        '${categoriesToInsert.length} categories from Firebase.',
      );

      // Reload AppCache from SQLite so it's an exact, duplicate-free mirror of
      // the DB after all upserts. Incremental AppCache.add* calls are avoided
      // because they have no duplicate guard and can race with UI loads.
      if (categoriesToInsert.isNotEmpty || linksToInsert.isNotEmpty || excludeGuestDefault) {
        AppCache.invalidateAll();
        await CategoryRepository.ensureLoaded();
        await LinkRepository.ensureLoaded();
      }

      // Clear queue and stamp the reconcile time so the 24h pass is skipped.
      _clearInMemory();
      _box.remove(_storageKey);
      _box.write(_lastReconciledKey, DateTime.now().toIso8601String());
    } catch (e) {
      log('Post-login sync failed (will retry next launch): $e');
    }
  }

  // ── Reconcile (diff local vs Firebase, push missing) ──────────────────────

  static const _lastReconciledKey = 'last_reconciled_at';

  /// Compares ALL local SQLite records with Firebase.
  /// Pushes any local records that are missing on Firebase (1 GET + 1 UPDATE max).
  /// Throttled to once every 24 hours to save requests.
  Future<void> reconcileLocalToFirebase() async {
    // Throttle check
    final lastRaw = _box.read<String>(_lastReconciledKey);
    if (lastRaw != null) {
      final last = DateTime.tryParse(lastRaw);
      if (last != null && DateTime.now().difference(last).inHours < 24) {
        log('Reconcile: skipped (last run < 24h ago).');
        return;
      }
    }

    final user = await FirebaseService.authStateChanges.first;
    final userId = user?.uid;
    if (userId == null) {
      log('Reconcile: skipped (not authenticated).');
      return;
    }

    try {
      // Ensure local cache is populated
      await LinkRepository.ensureLoaded();
      await CategoryRepository.ensureLoaded();

      // 1 GET — fetch existing Firebase data
      final remoteData = await FirebaseService.getUserData(userId);
      final remoteLinks = Map<String, dynamic>.from(remoteData?['links'] as Map? ?? {});
      final remoteCategories = Map<String, dynamic>.from(remoteData?['categories'] as Map? ?? {});

      // Diff: find local records missing from Firebase
      final updates = <String, dynamic>{};

      for (final link in AppCache.links) {
        if (!remoteLinks.containsKey(link.id)) {
          updates['links/${link.id}'] = link.toJson();
        }
      }
      for (final cat in AppCache.categories) {
        final id = cat.id;
        if (id == null || id.isEmpty) continue;
        if (!remoteCategories.containsKey(id)) {
          updates['categories/$id'] = cat.toJson();
        }
      }

      if (updates.isEmpty) {
        log(
          'Reconcile: already in sync '
          '(${AppCache.links.length} links, ${AppCache.categories.length} categories).',
        );
      } else {
        // 1 UPDATE — push all missing records in one request
        await FirebaseService.applyUserDelta(userId, updates);
        log('Reconcile: pushed ${updates.length} missing paths to Firebase.');
      }

      _box.write(_lastReconciledKey, DateTime.now().toIso8601String());
    } catch (e) {
      log('Reconcile failed (will retry next launch): $e');
    }
  }
}
