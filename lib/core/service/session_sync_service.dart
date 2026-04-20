import 'dart:convert';
import 'dart:developer';

import 'package:get_storage/get_storage.dart';
import 'package:keep_link/core/cache/app_cache.dart';
import 'package:keep_link/core/repository/category_repository.dart';
import 'package:keep_link/core/repository/link_repository.dart';
import 'package:keep_link/core/service/firebase_service.dart';
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
