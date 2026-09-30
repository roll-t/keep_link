import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/data/repositories/friend_repository.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/core/services/backend/friend_connection_service.dart';
import 'package:keep_link/core/services/platform/local_notification_service.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/application/model/friend_request_model.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';

class FriendController extends GetxController {
  static const int maxFriends = 10;
  static final RxInt pendingRequestCount = 0.obs;
  static final RxInt pendingSharedCount = 0.obs;
  static final RxBool hasUnreadShare = false.obs;
  static final Rxn<User> currentUser = Rxn<User>();

  final searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool isSearching = false.obs;
  final RxList<FriendModel> visibleFriends = <FriendModel>[].obs;
  final RxList<FriendRequestModel> incomingRequests =
      <FriendRequestModel>[].obs;
  final RxList<String> pendingRequestUserIds = <String>[].obs;
  final RxSet<String> processingRequestUserIds = <String>{}.obs;
  final Set<String> _sendingRequestUserIds = {};
  final Set<String> _deletingFriendUserIds = {};
  StreamSubscription<List<FriendRequestModel>>? _requestWatcher;
  StreamSubscription<Set<String>>? _sharedCategoryWatcher;
  StreamSubscription<Set<String>>? _sharedLinkWatcher;
  StreamSubscription<Set<String>>? _sharedCategoryEventWatcher;
  StreamSubscription<Set<String>>? _sharedLinkEventWatcher;
  StreamSubscription<int>? _friendsWatcher;
  StreamSubscription<User?>? _authSub;
  Timer? _sharedNotificationTimer;
  int _queuedSharedNotificationCount = 0;
  final Map<String, StreamSubscription<Map<String, int>>> _linkCountWatchers =
      {};
  final Map<String, Set<String>> _watchedCategoryIds = {};
  final Map<String, int> _knownLinkCounts = {}; // key: "ownerUid/catId"
  Future<void>? _fetchFuture;
  Future<void>? _syncFuture;
  bool _fetchQueued = false;
  static String? activeConversationFriendId;
  bool _forceRemoteOnNextFetch = false;
  String? _activeUserId;
  bool _isFriendPageActive = false;
  bool _isSharedInitialLoad = true;
  bool _isSharedLinkInitialLoad = true;
  bool _isFriendsInitialLoad = true;
  Set<String> _knownSharedKeys = {};
  Set<String> _knownSharedLinkKeys = {};
  Set<String> _knownCategoryEventKeys = {};
  Set<String> _knownLinkEventKeys = {};
  Set<String> _unseenCategoryKeys = {};
  Set<String> _unseenLinkKeys = {};

  int get totalFriends => AppCache.friends.length;
  int get remainingSlots => maxFriends - totalFriends;
  bool get hasReachedLimit => totalFriends >= maxFriends;

  @override
  void onInit() {
    super.onInit();
    final initialUser = FirebaseService.currentUser;
    _activeUserId = initialUser?.uid;
    currentUser.value = initialUser;
    if (_activeUserId != null) {
      hasUnreadShare.value = AppGetStorage.getHasUnreadShare(_activeUserId!);
    }
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
    debounce(
      searchQuery,
      (_) => _applyFilters(),
      time: const Duration(milliseconds: 200),
    );
    ever(AppCache.friends, (_) => _applyFilters());
    fetchFriends();
    _startRequestWatcher();
    _startSharedCategoryWatcher();
    _startSharedLinkWatcher();
    _startSharedEventWatchers();
    _startFriendsWatcher();
    // `authStateChanges` always replays the current auth state as its first
    // event. Without this guard that first event repeats the exact fetch +
    // watcher setup already done above, doubling every Firebase read on init.
    var isFirstAuthEvent = true;
    _authSub = FirebaseService.authStateChanges.listen((user) {
      if (isFirstAuthEvent) {
        isFirstAuthEvent = false;
        if (user?.uid == initialUser?.uid) return;
      }
      final nextUserId = user?.uid;
      final accountChanged = _activeUserId != nextUserId;
      _activeUserId = nextUserId;
      currentUser.value = user;
      if (accountChanged) {
        // Never keep another account's friends on screen or restore their
        // local favorites while the new account is being fetched.
        AppCache.invalidateFriends();
        visibleFriends.clear();
        pendingRequestUserIds.clear();
        _forceRemoteOnNextFetch = user != null;
        hasUnreadShare.value =
            nextUserId != null ? AppGetStorage.getHasUnreadShare(nextUserId) : false;
      }
      if (user != null) {
        fetchFriends();
        _startRequestWatcher();
        _startSharedCategoryWatcher();
        _startSharedLinkWatcher();
        _startSharedEventWatchers();
        _startFriendsWatcher();
      } else {
        _requestWatcher?.cancel();
        _requestWatcher = null;
        incomingRequests.clear();
        pendingRequestCount.value = 0;
        _sharedCategoryWatcher?.cancel();
        _sharedCategoryWatcher = null;
        _sharedLinkWatcher?.cancel();
        _sharedLinkWatcher = null;
        _sharedCategoryEventWatcher?.cancel();
        _sharedCategoryEventWatcher = null;
        _sharedLinkEventWatcher?.cancel();
        _sharedLinkEventWatcher = null;
        _knownSharedKeys = {};
        _knownSharedLinkKeys = {};
        _knownCategoryEventKeys = {};
        _knownLinkEventKeys = {};
        _unseenCategoryKeys = {};
        _unseenLinkKeys = {};
        pendingSharedCount.value = 0;
        hasUnreadShare.value = false;
        for (final sub in _linkCountWatchers.values) {
          sub.cancel();
        }
        _linkCountWatchers.clear();
        _watchedCategoryIds.clear();
        _knownLinkCounts.clear();
        _friendsWatcher?.cancel();
        _friendsWatcher = null;
      }
    });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _requestWatcher?.cancel();
    _sharedCategoryWatcher?.cancel();
    _sharedLinkWatcher?.cancel();
    _sharedCategoryEventWatcher?.cancel();
    _sharedLinkEventWatcher?.cancel();
    _friendsWatcher?.cancel();
    for (final sub in _linkCountWatchers.values) {
      sub.cancel();
    }
    _sharedNotificationTimer?.cancel();
    _linkCountWatchers.clear();
    _watchedCategoryIds.clear();
    searchController.dispose();
    super.onClose();
  }

  void _startRequestWatcher() {
    if (FirebaseService.currentUser == null) return;
    _requestWatcher?.cancel();
    _requestWatcher = FirebaseService.watchIncomingFriendRequests().listen(
      (requests) {
        final newCount = requests.length;
        incomingRequests.assignAll(requests);
        pendingRequestCount.value = newCount;
      },
      onError: (Object error) {
        // permission-denied khi đăng xuất — huỷ listener, reset state
        _requestWatcher?.cancel();
        _requestWatcher = null;
        incomingRequests.clear();
        pendingRequestCount.value = 0;
      },
      cancelOnError: true,
    );
  }

  void _startFriendsWatcher() {
    if (FirebaseService.currentUser == null) return;
    _friendsWatcher?.cancel();
    _isFriendsInitialLoad = true;
    int lastCount = AppCache.friends.length;
    _friendsWatcher = FirebaseService.watchFriendsCount().listen(
      (remoteCount) async {
        if (_isFriendsInitialLoad) {
          lastCount = remoteCount;
          _isFriendsInitialLoad = false;
          return;
        }
        // Đồng bộ cả khi tăng lẫn giảm (người phía bên kia có thể xoá kết nối).
        if (remoteCount != lastCount) {
          lastCount = remoteCount;
          await _syncRemoteFriendState(includeOutgoingRequests: false);
        }
      },
      onError: (Object _) {
        _friendsWatcher?.cancel();
        _friendsWatcher = null;
      },
      cancelOnError: true,
    );
  }

  void _startSharedCategoryWatcher() {
    final uid = FirebaseService.currentUser?.uid;
    if (uid == null) return;
    _sharedCategoryWatcher?.cancel();
    _isSharedInitialLoad = true;
    _sharedCategoryWatcher = FirebaseService.watchSharedCategoryAccess().listen(
      (keys) {
        if (_isSharedInitialLoad) {
          _isSharedInitialLoad = false;
          _knownSharedKeys = Set.from(keys);
          final seenKeys = AppGetStorage.getSeenSharedKeys(uid);
          final notifiedKeys = AppGetStorage.getNotifiedSharedKeys(uid);
          _unseenCategoryKeys = _isFriendPageActive
              ? <String>{}
              : keys.difference(seenKeys);
          if (_unseenCategoryKeys.isNotEmpty && !_isFriendPageActive) {
            hasUnreadShare.value = true;
            AppGetStorage.setHasUnreadShare(uid, true);
          }
          AppGetStorage.setNotifiedSharedKeys(uid, {
            ...notifiedKeys.where((key) => key.startsWith('link:')),
            ...keys,
          });
          if (_isFriendPageActive) _saveSeenKeys(uid);
          _updatePendingSharedCount();
          if (_isFriendPageActive) _reconcileLinkWatchers(keys);
          return;
        }
        // Real-time: có key mới xuất hiện
        final newKeys = keys.difference(_knownSharedKeys);
        final removedKeys = _knownSharedKeys.difference(keys);
        if (newKeys.isNotEmpty) {
          if (_isFriendPageActive) {
            _refreshSharedDataIfVisible();
          } else {
            final fromActiveFriend =
                activeConversationFriendId != null &&
                newKeys.every(
                  (k) => k.startsWith('$activeConversationFriendId/'),
                );
            if (!fromActiveFriend) {
              _unseenCategoryKeys.addAll(newKeys);
              hasUnreadShare.value = true;
              AppGetStorage.setHasUnreadShare(uid, true);
            }
          }
        }
        _unseenCategoryKeys.removeAll(removedKeys);
        final notifiedKeys = AppGetStorage.getNotifiedSharedKeys(uid);
        AppGetStorage.setNotifiedSharedKeys(uid, {
          ...notifiedKeys.where(
            (key) => key.startsWith('link:') || !removedKeys.contains(key),
          ),
          ...newKeys,
        });
        _updatePendingSharedCount();
        if (newKeys.isNotEmpty || removedKeys.isNotEmpty) {
          SharedCategoryController.invalidateCache();
          if (removedKeys.isNotEmpty && _isFriendPageActive) {
            _refreshSharedDataIfVisible();
          }
        }
        _knownSharedKeys = Set.from(keys);
        if (_isFriendPageActive) _reconcileLinkWatchers(keys);
      },
      onError: (Object error) {
        _sharedCategoryWatcher?.cancel();
        _sharedCategoryWatcher = null;
        _knownSharedKeys = {};
        _unseenCategoryKeys = {};
        _updatePendingSharedCount();
      },
      cancelOnError: true,
    );
  }

  void _startSharedLinkWatcher() {
    final uid = FirebaseService.currentUser?.uid;
    if (uid == null) return;
    _sharedLinkWatcher?.cancel();
    _isSharedLinkInitialLoad = true;
    _sharedLinkWatcher = FirebaseService.watchSharedLinkAccess().listen(
      (keys) {
        final prefixedKeys = keys.map((key) => 'link:$key').toSet();
        if (_isSharedLinkInitialLoad) {
          _isSharedLinkInitialLoad = false;
          _knownSharedLinkKeys = Set.from(keys);
          final seenKeys = AppGetStorage.getSeenSharedKeys(uid);
          final notifiedKeys = AppGetStorage.getNotifiedSharedKeys(uid);
          _unseenLinkKeys = _isFriendPageActive
              ? <String>{}
              : prefixedKeys.difference(seenKeys);
          if (_unseenLinkKeys.isNotEmpty && !_isFriendPageActive) {
            hasUnreadShare.value = true;
            AppGetStorage.setHasUnreadShare(uid, true);
          }
          AppGetStorage.setNotifiedSharedKeys(uid, {
            ...notifiedKeys.where((key) => !key.startsWith('link:')),
            ...prefixedKeys,
          });
          if (_isFriendPageActive) _saveSeenKeys(uid);
          _updatePendingSharedCount();
          return;
        }

        final newKeys = keys.difference(_knownSharedLinkKeys);
        final removedKeys = _knownSharedLinkKeys.difference(keys);
        if (newKeys.isNotEmpty) {
          SharedCategoryController.invalidateCache();
          if (_isFriendPageActive) {
            _refreshSharedDataIfVisible();
          } else {
            final fromActiveFriend =
                activeConversationFriendId != null &&
                newKeys.every(
                  (k) => k.startsWith('$activeConversationFriendId/'),
                );
            if (!fromActiveFriend) {
              _unseenLinkKeys.addAll(newKeys.map((key) => 'link:$key'));
              hasUnreadShare.value = true;
              AppGetStorage.setHasUnreadShare(uid, true);
            }
          }
        }
        _unseenLinkKeys.removeAll(removedKeys.map((key) => 'link:$key'));
        final notifiedKeys = AppGetStorage.getNotifiedSharedKeys(uid);
        final removedPrefixedKeys = removedKeys.map((key) => 'link:$key');
        AppGetStorage.setNotifiedSharedKeys(uid, {
          ...notifiedKeys.where((key) => !removedPrefixedKeys.contains(key)),
          ...newKeys.map((key) => 'link:$key'),
        });
        if (removedKeys.isNotEmpty) {
          SharedCategoryController.invalidateCache();
          if (_isFriendPageActive) _refreshSharedDataIfVisible();
        }
        _knownSharedLinkKeys = Set.from(keys);
        _updatePendingSharedCount();
      },
      onError: (Object _) {
        _sharedLinkWatcher?.cancel();
        _sharedLinkWatcher = null;
        _knownSharedLinkKeys = {};
        _unseenLinkKeys = {};
        _updatePendingSharedCount();
      },
      cancelOnError: true,
    );
  }

  void _updatePendingSharedCount() {
    pendingSharedCount.value =
        _unseenCategoryKeys.length + _unseenLinkKeys.length;
  }

  void _startSharedEventWatchers() {
    final uid = FirebaseService.currentUser?.uid;
    if (uid == null) return;
    _sharedCategoryEventWatcher?.cancel();
    _sharedLinkEventWatcher?.cancel();
    _knownCategoryEventKeys = {};
    _knownLinkEventKeys = {};

    var categoryInitial = true;
    _sharedCategoryEventWatcher =
        FirebaseService.watchIncomingCategoryShareEvents().listen(
          (keys) {
            if (categoryInitial) {
              categoryInitial = false;
              _notifyForUnreportedShareEvents(
                uid: uid,
                keys: keys,
                type: 'category',
                notifyWhileViewing: true,
              );
              _knownCategoryEventKeys = Set.from(keys);
              return;
            }
            _notifyForNewShareEvents(
              uid: uid,
              keys: keys,
              previousKeys: _knownCategoryEventKeys,
              type: 'category',
            );
            _knownCategoryEventKeys = Set.from(keys);
          },
          onError: (Object _) {
            _sharedCategoryEventWatcher?.cancel();
            _sharedCategoryEventWatcher = null;
          },
          cancelOnError: true,
        );

    var linkInitial = true;
    _sharedLinkEventWatcher = FirebaseService.watchIncomingLinkShareEvents()
        .listen(
          (keys) {
            if (linkInitial) {
              linkInitial = false;
              _notifyForUnreportedShareEvents(
                uid: uid,
                keys: keys,
                type: 'link',
                notifyWhileViewing: true,
              );
              _knownLinkEventKeys = Set.from(keys);
              return;
            }
            _notifyForNewShareEvents(
              uid: uid,
              keys: keys,
              previousKeys: _knownLinkEventKeys,
              type: 'link',
            );
            _knownLinkEventKeys = Set.from(keys);
          },
          onError: (Object _) {
            _sharedLinkEventWatcher?.cancel();
            _sharedLinkEventWatcher = null;
          },
          cancelOnError: true,
        );
  }

  void _notifyForNewShareEvents({
    required String uid,
    required Set<String> keys,
    required Set<String> previousKeys,
    required String type,
  }) {
    final newKeys = keys.difference(previousKeys);
    if (newKeys.isEmpty) return;
    final activeFriend = activeConversationFriendId;
    final visibleConversationEvents = activeFriend == null
        ? const <String>{}
        : newKeys.where((key) => key.startsWith('$activeFriend/')).toSet();
    _notifyForUnreportedShareEvents(
      uid: uid,
      keys: newKeys.difference(visibleConversationEvents),
      type: type,
      notifyWhileViewing: false,
    );
  }

  void _notifyForUnreportedShareEvents({
    required String uid,
    required Set<String> keys,
    required String type,
    required bool notifyWhileViewing,
  }) {
    if (keys.isEmpty) return;
    final notified = AppGetStorage.getNotifiedShareEventKeys(uid);
    final identities = keys.map((key) => '$type:$key').toSet();
    final unreported = identities.difference(notified);
    if (unreported.isEmpty) return;

    AppGetStorage.setNotifiedShareEventKeys(uid, {...notified, ...unreported});
    if (!_isFriendPageActive || notifyWhileViewing) {
      _queueSharedItemsNotification(unreported.length);
    }
    if (!_isFriendPageActive) {
      hasUnreadShare.value = true;
      AppGetStorage.setHasUnreadShare(uid, true);
    }
  }

  /// Category and link access live in two RTDB streams. A single share batch
  /// may update both at nearly the same time, so debounce briefly and present
  /// one notification with the combined item count instead of one popup per
  /// link/category.
  void _queueSharedItemsNotification(int count) {
    if (count <= 0) return;
    _queuedSharedNotificationCount += count;
    _sharedNotificationTimer?.cancel();
    _sharedNotificationTimer = Timer(const Duration(milliseconds: 250), () {
      final total = _queuedSharedNotificationCount;
      _queuedSharedNotificationCount = 0;
      if (total <= 0) return;
      LocalNotificationService.showSharedCategoryNotification(
        title: 'Linkeep',
        body: 'shared_new_items_received'.trParams({'count': '$total'}),
      );
    });
  }

  void _refreshSharedDataIfVisible() {
    if (!Get.isRegistered<SharedCategoryController>()) return;
    Get.find<SharedCategoryController>().loadAllSharedData(force: true);
  }

  /// Đánh dấu tất cả danh mục chia sẻ hiện tại là "đã xem"
  static void markSharedCategoriesAsSeen() {
    final uid = FirebaseService.currentUser?.uid;
    if (uid == null) return;
    pendingSharedCount.value = 0;
    hasUnreadShare.value = false;
    AppGetStorage.setHasUnreadShare(uid, false);
    if (Get.isRegistered<FriendController>()) {
      final ctrl = Get.find<FriendController>();
      ctrl._unseenCategoryKeys.clear();
      ctrl._unseenLinkKeys.clear();
    }
    _saveSeenKeys(uid);
  }

  static void _saveSeenKeys(String uid) {
    if (Get.isRegistered<FriendController>()) {
      final ctrl = Get.find<FriendController>();
      AppGetStorage.setSeenSharedKeys(uid, {
        ...ctrl._knownSharedKeys,
        ...ctrl._knownSharedLinkKeys.map((key) => 'link:$key'),
      });
    }
  }

  /// Group keys ("ownerUid/catId") by ownerUid -> Set of catIds
  Map<String, Set<String>> _ownerCatMap(Set<String> keys) {
    final map = <String, Set<String>>{};
    for (final key in keys) {
      final slash = key.indexOf('/');
      if (slash <= 0) continue;
      final owner = key.substring(0, slash);
      final cat = key.substring(slash + 1);
      map.putIfAbsent(owner, () => {}).add(cat);
    }
    return map;
  }

  /// Sync link-count watchers to match the current set of shared keys.
  void _reconcileLinkWatchers(Set<String> keys) {
    final ownerCats = _ownerCatMap(keys);

    // Cancel watchers for owners no longer in the shared set
    final removed = _linkCountWatchers.keys
        .where((o) => !ownerCats.containsKey(o))
        .toList();
    for (final owner in removed) {
      _linkCountWatchers.remove(owner)?.cancel();
      _watchedCategoryIds.remove(owner);
      _knownLinkCounts.removeWhere((k, _) => k.startsWith('$owner/'));
    }

    // Add / refresh watchers for each owner
    for (final entry in ownerCats.entries) {
      _startLinkWatcherForOwner(entry.key, entry.value);
    }
  }

  void _startLinkWatcherForOwner(String ownerUid, Set<String> catIds) {
    final current = _watchedCategoryIds[ownerUid];
    if (current != null &&
        current.length == catIds.length &&
        current.every(catIds.contains) &&
        _linkCountWatchers.containsKey(ownerUid)) {
      return;
    }

    // Chỉ thay listener khi tập category thực sự thay đổi.
    _linkCountWatchers.remove(ownerUid)?.cancel();
    _watchedCategoryIds[ownerUid] = Set.from(catIds);

    bool isInitial = true;
    _linkCountWatchers[ownerUid] =
        FirebaseService.watchOwnerLinksCount(
          ownerUid: ownerUid,
          sharedCatIds: Set.from(catIds),
        ).listen(
          (counts) {
            if (isInitial) {
              // Ghi nhận baseline, không thông báo
              isInitial = false;
              counts.forEach((catId, count) {
                _knownLinkCounts['$ownerUid/$catId'] = count;
              });
              return;
            }
            // Phát hiện catId nào có count tăng
            final newLinkCatIds = <String>[];
            counts.forEach((catId, count) {
              final key = '$ownerUid/$catId';
              final prev = _knownLinkCounts[key] ?? 0;
              if (count > prev) newLinkCatIds.add(catId);
              _knownLinkCounts[key] = count;
            });
            if (newLinkCatIds.isNotEmpty) {
              SharedCategoryController.invalidateCache();
              // Nếu user đang xem danh sách link của category đó thì không tăng badge
              // (stream trong SharedCategoryController đã tự update)
              String? viewingCatId;
              if (Get.isRegistered<SharedCategoryController>()) {
                final active =
                    Get.find<SharedCategoryController>().activeSharedCategory;
                if (active != null && active.ownerUid == ownerUid) {
                  viewingCatId = active.categoryId;
                }
              }
              final unviewedCount = newLinkCatIds
                  .where((id) => id != viewingCatId)
                  .length;
              if (unviewedCount > 0) {
                _unseenCategoryKeys.addAll(
                  newLinkCatIds
                      .where((id) => id != viewingCatId)
                      .map((id) => '$ownerUid/$id'),
                );
                _updatePendingSharedCount();
              }
            }
          },
          onError: (Object _) {
            _linkCountWatchers.remove(ownerUid)?.cancel();
            _watchedCategoryIds.remove(ownerUid);
          },
          cancelOnError: true,
        );
  }

  void setFriendPageActive(bool active) {
    if (_isFriendPageActive == active) return;
    _isFriendPageActive = active;
    if (active) {
      _reconcileLinkWatchers(_knownSharedKeys);
      return;
    }
    for (final sub in _linkCountWatchers.values) {
      sub.cancel();
    }
    _linkCountWatchers.clear();
    _watchedCategoryIds.clear();
    _knownLinkCounts.clear();
  }

  Future<void> fetchFriends() async {
    final pending = _fetchFuture;
    if (pending != null) {
      // Authentication may change while an earlier account fetch is still in
      // flight. Queue one fresh pass instead of dropping the new request.
      _fetchQueued = true;
      return pending;
    }
    final fetch = _performFetchFriends();
    _fetchFuture = fetch;
    try {
      await fetch;
    } finally {
      if (identical(_fetchFuture, fetch)) _fetchFuture = null;
    }
    if (_fetchQueued) {
      _fetchQueued = false;
      await fetchFriends();
    }
  }

  Future<void> _performFetchFriends() async {
    try {
      errorMessage.value = null;
      isLoading.value = !AppCache.friendsLoaded;
      final forceRemote = _forceRemoteOnNextFetch;
      final targetUserId = FirebaseService.currentUser?.uid;
      if (!forceRemote) {
        await FriendRepository.ensureLoaded();
        _applyFilters();
      }
      await _syncRemoteFriendState(
        preserveFavorites: !forceRemote,
        requireFresh: forceRemote,
      );
      if (forceRemote && FirebaseService.currentUser?.uid == targetUserId) {
        _forceRemoteOnNextFetch = false;
      }
      _applyFilters();
    } catch (error) {
      debugPrint('Fetch friends error: $error');
      errorMessage.value = 'Không thể tải danh sách bạn bè. Vui lòng thử lại.';
    } finally {
      isLoading.value = false;
    }
  }

  void openSearch() => isSearching.value = true;

  void closeSearch() {
    isSearching.value = false;
    searchController.clear();
    searchQuery.value = '';
    _applyFilters();
  }

  Future<bool> addFriendFromLink(String rawInput) async {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      AppToast.warning('friend_sign_in_required'.tr);
      return false;
    }
    if (hasReachedLimit) {
      AppToast.warning('friend_limit_reached'.trParams({'0': '$maxFriends'}));
      return false;
    }

    final payload = FriendConnectionService.parseLink(rawInput);
    if (payload == null) {
      AppToast.error('friend_invalid_link'.tr);
      return false;
    }
    if (payload.userId == currentUser.uid) {
      AppToast.warning('friend_cannot_add_self'.tr);
      return false;
    }

    final existing = AppCache.friends.firstWhereOrNull(
      (friend) => friend.friendUserId == payload.userId,
    );
    if (existing != null) {
      AppToast.warning('friend_already_exists'.tr);
      return false;
    }

    return _sendFriendRequest(
      userId: payload.userId,
      displayName: payload.displayName,
      email: payload.email,
      photoUrl: payload.photoUrl,
      sourceLink: payload.rawLink,
    );
  }

  Future<bool> addFriendFromEmail(String rawEmail) async {
    final email = rawEmail.trim().toLowerCase();
    if (email.isEmpty ||
        !GetUtils.isEmail(email) ||
        !email.endsWith('@gmail.com')) {
      AppToast.error('friend_invalid_email'.tr);
      return false;
    }

    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      AppToast.warning('friend_sign_in_required'.tr);
      return false;
    }
    if (hasReachedLimit) {
      AppToast.warning('friend_limit_reached'.trParams({'0': '$maxFriends'}));
      return false;
    }
    if ((currentUser.email ?? '').trim().toLowerCase() == email) {
      AppToast.warning('friend_cannot_add_self'.tr);
      return false;
    }

    final existingByEmail = AppCache.friends.firstWhereOrNull(
      (friend) => (friend.email ?? '').trim().toLowerCase() == email,
    );
    if (existingByEmail != null) {
      AppToast.warning('friend_already_exists'.tr);
      return false;
    }

    final profile = await FirebaseService.findUserProfileByEmail(email);
    if (profile == null) {
      AppToast.error('friend_email_not_found'.tr);
      return false;
    }

    final userId = profile['uid'] ?? '';
    final profileDisplayName = profile['displayName'] ?? '';
    final profileEmail = profile['email'];
    final profilePhoto = profile['photoUrl'];

    if (userId.isEmpty) {
      AppToast.error('friend_email_not_found'.tr);
      return false;
    }
    if (userId == currentUser.uid) {
      AppToast.warning('friend_cannot_add_self'.tr);
      return false;
    }

    final fallbackName = (profileEmail ?? email).split('@').first;
    final safeDisplayName = profileDisplayName.trim().isEmpty
        ? fallbackName
        : profileDisplayName;

    return _sendFriendRequest(
      userId: userId,
      displayName: safeDisplayName,
      email: profileEmail,
      photoUrl: profilePhoto,
      sourceLink: 'email:$email',
    );
  }

  Future<String?> readClipboardLink() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  Future<bool> addFriendFromClipboard() async {
    final text = await readClipboardLink();
    if (text == null) {
      AppToast.warning('friend_clipboard_empty'.tr);
      return false;
    }
    return addFriendFromLink(text);
  }

  Future<bool> acceptFriendRequest(FriendRequestModel request) async {
    if (!processingRequestUserIds.add(request.fromUserId)) return false;
    if (hasReachedLimit) {
      AppToast.warning('friend_limit_reached'.trParams({'0': '$maxFriends'}));
      processingRequestUserIds.remove(request.fromUserId);
      return false;
    }

    try {
      await FirebaseService.acceptFriendRequest(request);
      await _syncRemoteFriendState(includeOutgoingRequests: false);
      AppToast.success('friend_request_accepted'.tr);
      return true;
    } catch (_) {
      AppToast.error('friend_request_action_failed'.tr);
      return false;
    } finally {
      processingRequestUserIds.remove(request.fromUserId);
    }
  }

  Future<void> declineFriendRequest(FriendRequestModel request) async {
    if (!processingRequestUserIds.add(request.fromUserId)) return;
    try {
      await FirebaseService.declineFriendRequest(request.fromUserId);
      incomingRequests.removeWhere(
        (item) => item.fromUserId == request.fromUserId,
      );
      AppToast.warning('friend_request_declined'.tr);
    } catch (_) {
      AppToast.error('friend_request_action_failed'.tr);
    } finally {
      processingRequestUserIds.remove(request.fromUserId);
    }
  }

  void confirmDeleteFriend(FriendModel friend) {
    DialogUtils.showConfirm(
      alertType: AlertType.warning,
      title: 'Delete Friend'.tr,
      content: 'delete_friend_confirm'.trParams({'0': friend.displayName}),
      confirmText: 'Delete'.tr,
      cancelText: 'Cancel'.tr,
      onConfirm: () async {
        if (!_deletingFriendUserIds.add(friend.friendUserId)) return;
        Get.back();
        try {
          await FirebaseService.removeFriend(friend.friendUserId);
          await _syncRemoteFriendState(includeOutgoingRequests: false);
          AppCache.removeSharedFriendFromAll(friend.friendUserId);
          SharedCategoryController.invalidateCache();
          if (_isFriendPageActive &&
              Get.isRegistered<SharedCategoryController>()) {
            await Get.find<SharedCategoryController>().loadSharedCategories(
              force: true,
            );
          }
          AppToast.success('friend_deleted_success'.tr);
        } catch (error) {
          debugPrint('Delete friend error: $error');
          AppToast.error('friend_request_action_failed'.tr);
        } finally {
          _deletingFriendUserIds.remove(friend.friendUserId);
        }
      },
      onCancel: Get.back,
    );
  }

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();
    final filtered = AppCache.friends.where((friend) {
      if (query.isEmpty) return true;

      return friend.displayName.toLowerCase().contains(query) ||
          (friend.email?.toLowerCase().contains(query) ?? false) ||
          friend.friendUserId.toLowerCase().contains(query);
    }).toList();

    visibleFriends.assignAll(filtered);
  }

  Future<bool> _sendFriendRequest({
    required String userId,
    required String displayName,
    String? email,
    String? photoUrl,
    required String sourceLink,
  }) async {
    if (_sendingRequestUserIds.contains(userId)) return false;
    final existing = AppCache.friends.firstWhereOrNull(
      (friend) => friend.friendUserId == userId,
    );
    if (existing != null) {
      AppToast.warning('friend_already_exists'.tr);
      return false;
    }

    final incoming = incomingRequests.firstWhereOrNull(
      (request) => request.fromUserId == userId,
    );
    if (incoming != null) {
      return acceptFriendRequest(incoming);
    }

    if (pendingRequestUserIds.contains(userId)) {
      AppToast.warning('friend_request_already_sent'.tr);
      return false;
    }

    try {
      _sendingRequestUserIds.add(userId);
      await FirebaseService.sendFriendRequest(
        targetUserId: userId,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        sourceLink: sourceLink,
      );
      pendingRequestUserIds.add(userId);
      AppToast.success('friend_request_sent'.tr);
      return true;
    } catch (_) {
      AppToast.error('friend_request_action_failed'.tr);
      return false;
    } finally {
      _sendingRequestUserIds.remove(userId);
    }
  }

  Future<void> _syncRemoteFriendState({
    bool includeOutgoingRequests = true,
    bool preserveFavorites = true,
    bool requireFresh = false,
  }) async {
    final pending = _syncFuture;
    if (pending != null) {
      await pending;
      if (!requireFresh) return;
      return _performRemoteFriendSync(
        includeOutgoingRequests: includeOutgoingRequests,
        preserveFavorites: preserveFavorites,
      );
    }
    final sync = _performRemoteFriendSync(
      includeOutgoingRequests: includeOutgoingRequests,
      preserveFavorites: preserveFavorites,
    );
    _syncFuture = sync;
    try {
      await sync;
    } finally {
      if (identical(_syncFuture, sync)) _syncFuture = null;
    }
  }

  Future<void> _performRemoteFriendSync({
    required bool includeOutgoingRequests,
    bool preserveFavorites = true,
  }) async {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      incomingRequests.clear();
      pendingRequestUserIds.clear();
      return;
    }

    late final List<FriendModel> remoteFriends;
    List<String>? outgoingIds;
    if (includeOutgoingRequests) {
      final results = await Future.wait<dynamic>([
        FirebaseService.getRemoteFriends(),
        FirebaseService.getOutgoingFriendRequestUserIds(),
      ]);
      remoteFriends = results[0] as List<FriendModel>;
      outgoingIds = results[1] as List<String>;
    } else {
      remoteFriends = await FirebaseService.getRemoteFriends();
    }

    // Discard a response that belongs to an account which was replaced while
    // the network request was running.
    if (FirebaseService.currentUser?.uid != currentUser.uid) return;

    await FriendRepository.replaceAll(
      remoteFriends,
      preserveFavorites: preserveFavorites,
    );
    if (outgoingIds != null) pendingRequestUserIds.assignAll(outgoingIds);
  }
}
