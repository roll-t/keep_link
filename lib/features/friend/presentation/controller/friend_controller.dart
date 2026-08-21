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
  static final Rxn<User> currentUser = Rxn<User>();

  final searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool favoritesOnly = false.obs;
  final RxList<FriendModel> visibleFriends = <FriendModel>[].obs;
  final RxList<FriendRequestModel> incomingRequests = <FriendRequestModel>[].obs;
  final RxList<String> pendingRequestUserIds = <String>[].obs;
  StreamSubscription<List<FriendRequestModel>>? _requestWatcher;
  StreamSubscription<Set<String>>? _sharedCategoryWatcher;
  StreamSubscription<int>? _friendsWatcher;
  StreamSubscription<User?>? _authSub;
  final Map<String, StreamSubscription<Map<String, int>>> _linkCountWatchers = {};
  final Map<String, int> _knownLinkCounts = {}; // key: "ownerUid/catId"
  bool _isInitialLoad = true;
  bool _isSharedInitialLoad = true;
  bool _isFriendsInitialLoad = true;
  Set<String> _knownSharedKeys = {};

  int get totalFriends => AppCache.friends.length;
  int get favoriteFriends => AppCache.friends.where((friend) => friend.isFavorite).length;
  int get remainingSlots => maxFriends - totalFriends;
  bool get hasReachedLimit => totalFriends >= maxFriends;

  @override
  void onInit() {
    super.onInit();
    final initialUser = FirebaseService.currentUser;
    currentUser.value = initialUser;
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
    debounce(searchQuery, (_) => _applyFilters(), time: const Duration(milliseconds: 200));
    ever(AppCache.friends, (_) => _applyFilters());
    fetchFriends();
    _startRequestWatcher();
    _startSharedCategoryWatcher();
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
      currentUser.value = user;
      if (user != null) {
        fetchFriends();
        _startRequestWatcher();
        _startSharedCategoryWatcher();
        _startFriendsWatcher();
      } else {
        _requestWatcher?.cancel();
        _requestWatcher = null;
        incomingRequests.clear();
        pendingRequestCount.value = 0;
        _sharedCategoryWatcher?.cancel();
        _sharedCategoryWatcher = null;
        _knownSharedKeys = {};
        pendingSharedCount.value = 0;
        for (final sub in _linkCountWatchers.values) {
          sub.cancel();
        }
        _linkCountWatchers.clear();
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
    _friendsWatcher?.cancel();
    for (final sub in _linkCountWatchers.values) {
      sub.cancel();
    }
    _linkCountWatchers.clear();
    searchController.dispose();
    super.onClose();
  }

  void _startRequestWatcher() {
    if (FirebaseService.currentUser == null) return;
    _requestWatcher?.cancel();
    _isInitialLoad = true;
    _requestWatcher = FirebaseService.watchIncomingFriendRequests().listen(
      (requests) {
        final newCount = requests.length;
        final oldCount = incomingRequests.length;
        incomingRequests.assignAll(requests);
        pendingRequestCount.value = newCount;
        if (!_isInitialLoad && newCount > oldCount) {
          LocalNotificationService.showFriendRequestNotification(
            title: 'Linkeep',
            body: 'friend_new_request_received'.tr,
          );
        }
        _isInitialLoad = false;
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
        // Khi số lượng tăng (bị ai đó chấp nhận lời mời) → sync lại
        if (remoteCount > lastCount) {
          lastCount = remoteCount;
          await _syncRemoteFriendState();
        } else {
          lastCount = remoteCount;
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
          // So sánh với keys đã xem lần trước (lưu local)
          final seenKeys = AppGetStorage.getSeenSharedKeys(uid);
          final unseen = keys.difference(seenKeys);
          pendingSharedCount.value = unseen.length;
          // Bắt đầu watch link counts cho tất cả shared categories
          _reconcileLinkWatchers(keys);
          return;
        }
        // Real-time: có key mới xuất hiện
        final newKeys = keys.difference(_knownSharedKeys);
        final removedKeys = _knownSharedKeys.difference(keys);
        if (newKeys.isNotEmpty) {
          pendingSharedCount.value += newKeys.length;
          LocalNotificationService.showSharedCategoryNotification(
            title: 'Linkeep',
            body: 'shared_new_category_received'.tr,
          );
        }
        if (newKeys.isNotEmpty || removedKeys.isNotEmpty) {
          SharedCategoryController.invalidateCache();
        }
        _knownSharedKeys = Set.from(keys);
        // Cập nhật link watchers khi shared categories thay đổi
        _reconcileLinkWatchers(keys);
      },
      onError: (Object error) {
        _sharedCategoryWatcher?.cancel();
        _sharedCategoryWatcher = null;
        _knownSharedKeys = {};
        pendingSharedCount.value = 0;
      },
      cancelOnError: true,
    );
  }

  /// Đánh dấu tất cả danh mục chia sẻ hiện tại là "đã xem"
  static void markSharedCategoriesAsSeen() {
    final uid = FirebaseService.currentUser?.uid;
    if (uid == null) return;
    pendingSharedCount.value = 0;
    _saveSeenKeys(uid);
  }

  static void _saveSeenKeys(String uid) {
    if (Get.isRegistered<FriendController>()) {
      final ctrl = Get.find<FriendController>();
      AppGetStorage.setSeenSharedKeys(uid, Set.from(ctrl._knownSharedKeys));
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
    final removed = _linkCountWatchers.keys.where((o) => !ownerCats.containsKey(o)).toList();
    for (final owner in removed) {
      _linkCountWatchers.remove(owner)?.cancel();
      _knownLinkCounts.removeWhere((k, _) => k.startsWith('$owner/'));
    }

    // Add / refresh watchers for each owner
    for (final entry in ownerCats.entries) {
      _startLinkWatcherForOwner(entry.key, entry.value);
    }
  }

  void _startLinkWatcherForOwner(String ownerUid, Set<String> catIds) {
    // Cancel existing watcher before replacing (catIds may have changed)
    _linkCountWatchers.remove(ownerUid)?.cancel();

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
              LocalNotificationService.showSharedCategoryNotification(
                title: 'Linkeep',
                body: 'shared_new_link_received'.tr,
              );
              // Nếu user đang xem danh sách link của category đó thì không tăng badge
              // (stream trong SharedCategoryController đã tự update)
              String? viewingCatId;
              if (Get.isRegistered<SharedCategoryController>()) {
                final active = Get.find<SharedCategoryController>().activeSharedCategory;
                if (active != null && active.ownerUid == ownerUid) {
                  viewingCatId = active.categoryId;
                }
              }
              final unviewedCount = newLinkCatIds.where((id) => id != viewingCatId).length;
              if (unviewedCount > 0) {
                pendingSharedCount.value += unviewedCount;
              }
            }
          },
          onError: (Object _) {
            _linkCountWatchers.remove(ownerUid)?.cancel();
          },
          cancelOnError: true,
        );
  }

  Future<void> fetchFriends() async {
    try {
      isLoading.value = true;
      await FriendRepository.ensureLoaded();
      await _syncRemoteFriendState();
      _applyFilters();
      if (Get.isRegistered<SharedCategoryController>()) {
        Get.find<SharedCategoryController>().loadSharedCategories();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void toggleFavoritesOnly() {
    favoritesOnly.value = !favoritesOnly.value;
    _applyFilters();
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
      AppToast.showToast('friend_sign_in_required'.tr, Icons.login_rounded, color: Colors.orange);
      return false;
    }
    if (hasReachedLimit) {
      AppToast.showToast(
        'friend_limit_reached'.trParams({'0': '$maxFriends'}),
        Icons.people_outline_rounded,
        color: Colors.orange,
      );
      return false;
    }

    final payload = FriendConnectionService.parseLink(rawInput);
    if (payload == null) {
      AppToast.showToast('friend_invalid_link'.tr, Icons.error_outline_rounded, color: Colors.red);
      return false;
    }
    if (payload.userId == currentUser.uid) {
      AppToast.showToast('friend_cannot_add_self'.tr, Icons.info_outline_rounded, color: Colors.orange);
      return false;
    }

    final existing = AppCache.friends.firstWhereOrNull(
      (friend) => friend.friendUserId == payload.userId,
    );
    if (existing != null) {
      AppToast.showToast('friend_already_exists'.tr, Icons.info_outline_rounded, color: Colors.orange);
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
    if (email.isEmpty || !GetUtils.isEmail(email) || !email.endsWith('@gmail.com')) {
      AppToast.showToast('friend_invalid_email'.tr, Icons.error_outline_rounded, color: Colors.red);
      return false;
    }

    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      AppToast.showToast('friend_sign_in_required'.tr, Icons.login_rounded, color: Colors.orange);
      return false;
    }
    if (hasReachedLimit) {
      AppToast.showToast(
        'friend_limit_reached'.trParams({'0': '$maxFriends'}),
        Icons.people_outline_rounded,
        color: Colors.orange,
      );
      return false;
    }
    if ((currentUser.email ?? '').trim().toLowerCase() == email) {
      AppToast.showToast('friend_cannot_add_self'.tr, Icons.info_outline_rounded, color: Colors.orange);
      return false;
    }

    final existingByEmail = AppCache.friends.firstWhereOrNull(
      (friend) => (friend.email ?? '').trim().toLowerCase() == email,
    );
    if (existingByEmail != null) {
      AppToast.showToast('friend_already_exists'.tr, Icons.info_outline_rounded, color: Colors.orange);
      return false;
    }

    final profile = await FirebaseService.findUserProfileByEmail(email);
    if (profile == null) {
      AppToast.showToast('friend_email_not_found'.tr, Icons.error_outline_rounded, color: Colors.red);
      return false;
    }

    final userId = profile['uid'] ?? '';
    final profileDisplayName = profile['displayName'] ?? '';
    final profileEmail = profile['email'];
    final profilePhoto = profile['photoUrl'];

    if (userId.isEmpty) {
      AppToast.showToast('friend_email_not_found'.tr, Icons.error_outline_rounded, color: Colors.red);
      return false;
    }
    if (userId == currentUser.uid) {
      AppToast.showToast('friend_cannot_add_self'.tr, Icons.info_outline_rounded, color: Colors.orange);
      return false;
    }

    final fallbackName = (profileEmail ?? email).split('@').first;
    final safeDisplayName = profileDisplayName.trim().isEmpty ? fallbackName : profileDisplayName;

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
      AppToast.showToast('friend_clipboard_empty'.tr, Icons.warning_rounded, color: Colors.orange);
      return false;
    }
    return addFriendFromLink(text);
  }

  Future<void> acceptFriendRequest(FriendRequestModel request) async {
    if (hasReachedLimit) {
      AppToast.showToast(
        'friend_limit_reached'.trParams({'0': '$maxFriends'}),
        Icons.people_outline_rounded,
        color: Colors.orange,
      );
      return;
    }

    try {
      await FirebaseService.acceptFriendRequest(request);
      await _syncRemoteFriendState();
      AppToast.showToast('friend_request_accepted'.tr, Icons.check_circle_rounded, color: Colors.green);
    } catch (_) {
      AppToast.showToast(
        'friend_request_action_failed'.tr,
        Icons.error_outline_rounded,
        color: Colors.red,
      );
    }
  }

  Future<void> declineFriendRequest(FriendRequestModel request) async {
    try {
      await FirebaseService.declineFriendRequest(request.fromUserId);
      incomingRequests.removeWhere((item) => item.fromUserId == request.fromUserId);
      AppToast.showToast('friend_request_declined'.tr, Icons.info_outline_rounded, color: Colors.orange);
    } catch (_) {
      AppToast.showToast(
        'friend_request_action_failed'.tr,
        Icons.error_outline_rounded,
        color: Colors.red,
      );
    }
  }

  Future<void> toggleFavorite(FriendModel friend) async {
    final updated = friend.copyWith(isFavorite: !friend.isFavorite, updatedAt: DateTime.now());
    await FriendRepository.update(updated);
  }

  void confirmDeleteFriend(FriendModel friend) {
    DialogUtils.showConfirm(
      alertType: AlertType.warning,
      title: 'Delete Friend'.tr,
      content: 'delete_friend_confirm'.trParams({'0': friend.displayName}),
      confirmText: 'Delete'.tr,
      cancelText: 'Cancel'.tr,
      onConfirm: () async {
        await FirebaseService.removeFriend(friend.friendUserId);
        await _syncRemoteFriendState();
        // Xoá bạn khỏi sharedWithCache để ShareCategorySheet cập nhật ngay.
        AppCache.removeSharedFriendFromAll(friend.friendUserId);
        // Invalidate SharedCategoriesPage cache để lần mở tiếp sẽ fetch lại.
        SharedCategoryController.invalidateCache();
        // Nếu SharedCategoryController đang active, load lại ngay.
        if (Get.isRegistered<SharedCategoryController>()) {
          Get.find<SharedCategoryController>().loadSharedCategories();
        }
        Get.back();
        AppToast.showToast(
          'friend_deleted_success'.tr,
          Icons.check_circle_rounded,
          color: Colors.green,
        );
      },
      onCancel: Get.back,
    );
  }

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();
    final filtered = AppCache.friends.where((friend) {
      if (favoritesOnly.value && !friend.isFavorite) {
        return false;
      }
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
    final existing = AppCache.friends.firstWhereOrNull((friend) => friend.friendUserId == userId);
    if (existing != null) {
      AppToast.showToast('friend_already_exists'.tr, Icons.info_outline_rounded, color: Colors.orange);
      return false;
    }

    final incoming = incomingRequests.firstWhereOrNull((request) => request.fromUserId == userId);
    if (incoming != null) {
      await acceptFriendRequest(incoming);
      return true;
    }

    if (pendingRequestUserIds.contains(userId)) {
      AppToast.showToast(
        'friend_request_already_sent'.tr,
        Icons.info_outline_rounded,
        color: Colors.orange,
      );
      return false;
    }

    try {
      await FirebaseService.sendFriendRequest(
        targetUserId: userId,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        sourceLink: sourceLink,
      );
      pendingRequestUserIds.add(userId);
      AppToast.showToast('friend_request_sent'.tr, Icons.check_circle_rounded, color: Colors.green);
      return true;
    } catch (_) {
      AppToast.showToast(
        'friend_request_action_failed'.tr,
        Icons.error_outline_rounded,
        color: Colors.red,
      );
      return false;
    }
  }

  Future<void> _syncRemoteFriendState() async {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      incomingRequests.clear();
      pendingRequestUserIds.clear();
      return;
    }

    final results = await Future.wait<dynamic>([
      FirebaseService.getRemoteFriends(),
      FirebaseService.getIncomingFriendRequests(),
      FirebaseService.getOutgoingFriendRequestUserIds(),
    ]);

    final remoteFriends = results[0] as List<FriendModel>;
    final requests = results[1] as List<FriendRequestModel>;
    final outgoingIds = results[2] as List<String>;

    await FriendRepository.replaceAll(remoteFriends);
    incomingRequests.assignAll(requests);
    pendingRequestUserIds.assignAll(outgoingIds);
  }
}
