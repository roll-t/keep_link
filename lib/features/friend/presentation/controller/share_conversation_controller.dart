import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/repositories/category_repository.dart';
import 'package:keep_link/core/data/repositories/link_repository.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/application/model/shared_category_model.dart';
import 'package:keep_link/features/friend/application/model/shared_individual_link_model.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

class ShareConversationController extends GetxController {
  ShareConversationController({required this.friend});

  final FriendModel friend;
  final SharedCategoryController shared = Get.find<SharedCategoryController>();
  final ScrollController scrollController = ScrollController();

  final RxList<ShareConversationEntry> items = <ShareConversationEntry>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool hasNewItemsBelow = false.obs;
  final RxnString errorMessage = RxnString();

  Timer? _liveReloadDebounce;
  StreamSubscription? _incomingLinksSub;
  StreamSubscription? _incomingCategoriesSub;
  StreamSubscription? _outgoingLinksSub;
  StreamSubscription? _outgoingCategoriesSub;
  Future<void>? _loadFuture;
  int _loadGeneration = 0;
  bool _hasCompletedInitialLoad = false;
  bool _reloadQueued = false;
  bool _queuedForceShared = false;
  bool _queuedJumpToLatest = false;

  String get myDisplayName {
    final user = FirebaseService.currentUser;
    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    final email = user?.email?.trim() ?? '';
    return email.isNotEmpty ? email : 'Me';
  }

  String? get myPhotoUrl => FirebaseService.currentUser?.photoURL;

  @override
  void onInit() {
    super.onInit();
    final friendId = friend.friendUserId.trim();
    if (friendId.isEmpty) {
      errorMessage.value = 'Không xác định được người nhận.';
      isLoading.value = false;
      return;
    }
    FriendController.activeConversationFriendId = friendId;
    scrollController.addListener(_handleScroll);
    _startRealtimeWatchers();
  }

  @override
  void onReady() {
    super.onReady();
    load(showLoading: true, forceShared: true, jumpToLatest: true);
  }

  void _startRealtimeWatchers() {
    final friendId = friend.friendUserId;
    _incomingLinksSub = FirebaseService.watchIncomingLinksFromFriend(
      friendId,
    ).skip(1).listen((_) => _onRealtimeChange(), onError: (_) {});
    _incomingCategoriesSub = FirebaseService.watchIncomingCategoriesFromFriend(
      friendId,
    ).skip(1).listen((_) => _onRealtimeChange(), onError: (_) {});
    _outgoingLinksSub = FirebaseService.watchOutgoingLinksToFriend(
      friendId,
    ).skip(1).listen((_) => _onRealtimeChange(), onError: (_) {});
    _outgoingCategoriesSub = FirebaseService.watchOutgoingCategoriesToFriend(
      friendId,
    ).skip(1).listen((_) => _onRealtimeChange(), onError: (_) {});
  }

  void _onRealtimeChange() {
    _liveReloadDebounce?.cancel();
    _liveReloadDebounce = Timer(const Duration(milliseconds: 300), () {
      SharedCategoryController.invalidateCache();
      load(forceShared: true);
    });
  }

  Future<void> refreshConversation() => load(forceShared: true);

  Future<void> reloadAfterShare() =>
      load(forceShared: true, jumpToLatest: true);

  Future<void> load({
    bool showLoading = false,
    bool forceShared = false,
    bool jumpToLatest = false,
  }) async {
    final pending = _loadFuture;
    if (pending != null) {
      _reloadQueued = true;
      _queuedForceShared = _queuedForceShared || forceShared;
      _queuedJumpToLatest = _queuedJumpToLatest || jumpToLatest;
      await pending;
      return;
    }

    final generation = ++_loadGeneration;
    final wasNearBottom = isNearBottom;
    final previousKeys = items.map((item) => item.identityKey).toSet();
    final future = _performLoad(
      generation: generation,
      showLoading: showLoading,
      forceShared: forceShared,
      jumpToLatest: jumpToLatest,
      wasNearBottom: wasNearBottom,
      previousKeys: previousKeys,
    );
    _loadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_loadFuture, future)) _loadFuture = null;
      if (_reloadQueued && !isClosed) {
        final queuedForce = _queuedForceShared;
        final queuedJump = _queuedJumpToLatest;
        _reloadQueued = false;
        _queuedForceShared = false;
        _queuedJumpToLatest = false;
        unawaited(load(forceShared: queuedForce, jumpToLatest: queuedJump));
      }
    }
  }

  Future<void> _performLoad({
    required int generation,
    required bool showLoading,
    required bool forceShared,
    required bool jumpToLatest,
    required bool wasNearBottom,
    required Set<String> previousKeys,
  }) async {
    if (showLoading && items.isEmpty) {
      isLoading.value = true;
    } else if (_hasCompletedInitialLoad) {
      isRefreshing.value = true;
    }
    errorMessage.value = null;

    try {
      await Future.wait([
        CategoryRepository.ensureLoaded(),
        LinkRepository.ensureLoaded(),
        shared.loadAllSharedData(force: forceShared),
      ]);

      final outgoing = await Future.wait<dynamic>([
        FirebaseService.getCategoryIdsSharedWithFriend(friend.friendUserId),
        FirebaseService.getLinkIdsSharedWithFriend(friend.friendUserId),
        FirebaseService.getShareTimesWithFriend(friend.friendUserId),
      ]);
      final nextItems = await _composeItems(outgoing);
      if (generation != _loadGeneration || isClosed) return;

      final hasNewItem = nextItems.any(
        (item) => !previousKeys.contains(item.identityKey),
      );
      final isInitialLoad = !_hasCompletedInitialLoad;
      items.assignAll(nextItems);
      _hasCompletedInitialLoad = true;

      if (jumpToLatest || isInitialLoad || wasNearBottom) {
        scrollToLatest(animate: !isInitialLoad);
      } else if (hasNewItem) {
        hasNewItemsBelow.value = true;
      }
    } catch (error) {
      if (!isClosed) {
        errorMessage.value = 'Không thể tải cuộc trò chuyện. Hãy thử lại.';
      }
      debugPrint('Load share conversation error: $error');
    } finally {
      if (generation == _loadGeneration && !isClosed) {
        isLoading.value = false;
        isRefreshing.value = false;
      }
    }
  }

  Future<List<ShareConversationEntry>> _composeItems(
    List<dynamic> outgoing,
  ) async {
    final result = <ShareConversationEntry>[];
    for (final category in shared.sharedCategories.where(
      (item) => item.ownerUid == friend.friendUserId,
    )) {
      shared.markCategoryViewed(category);
      result.add(ShareConversationEntry.incomingCategory(category));
    }
    for (final item in shared.sharedIndividualLinks.where(
      (item) => item.ownerUid == friend.friendUserId,
    )) {
      shared.markLinkViewed(item);
      result.add(ShareConversationEntry.incomingLink(item));
    }

    final categoryIds = (outgoing[0] as List<String>).toSet();
    final linkIds = (outgoing[1] as List<String>).toSet();
    final shareTimes = outgoing[2] as Map<String, int>;
    Map<String, dynamic>? remoteCategories;
    Map<String, dynamic>? remoteLinks;

    Future<void> ensureRemoteContent() async {
      if (remoteCategories != null && remoteLinks != null) return;
      final userId = FirebaseService.currentUser?.uid;
      final userData = userId == null
          ? null
          : await FirebaseService.getUserData(userId);
      remoteCategories = userData?['categories'] is Map
          ? Map<String, dynamic>.from(userData!['categories'] as Map)
          : <String, dynamic>{};
      remoteLinks = userData?['links'] is Map
          ? Map<String, dynamic>.from(userData!['links'] as Map)
          : <String, dynamic>{};
    }

    for (final categoryId in categoryIds) {
      final sharedTime = _shareTime(categoryId, shareTimes);
      final local = AppCache.categories.firstWhereOrNull(
        (category) => category.id == categoryId,
      );
      if (local != null) {
        result.add(
          ShareConversationEntry.outgoingCategory(
            local,
            sharedTime: sharedTime,
          ),
        );
        continue;
      }
      await ensureRemoteContent();
      final raw = remoteCategories![categoryId];
      if (raw is Map) {
        final json = Map<String, dynamic>.from(raw)..['id'] = categoryId;
        result.add(
          ShareConversationEntry.outgoingCategory(
            CategoryModel.fromJson(json),
            sharedTime: sharedTime,
          ),
        );
      }
    }

    for (final linkId in linkIds) {
      final sharedTime = _shareTime(linkId, shareTimes);
      final local = AppCache.links.firstWhereOrNull(
        (link) => link.id == linkId,
      );
      if (local != null) {
        result.add(
          ShareConversationEntry.outgoingLink(local, sharedTime: sharedTime),
        );
        continue;
      }
      await ensureRemoteContent();
      final raw = remoteLinks![linkId];
      if (raw is Map) {
        result.add(
          ShareConversationEntry.outgoingLink(
            LinkModel.fromJson(Map<String, dynamic>.from(raw), id: linkId),
            sharedTime: sharedTime,
          ),
        );
      }
    }

    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  DateTime? _shareTime(String id, Map<String, int> remoteTimes) {
    final timestamp =
        FirebaseService.getSessionShareTime(friend.friendUserId, id) ??
        remoteTimes[id];
    return timestamp == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<List<LinkModel>> loadOutgoingCategoryLinks(
    CategoryModel category,
  ) async {
    var links = AppCache.links
        .where((link) => link.categoryId == category.id)
        .toList();
    if (links.isNotEmpty) return links;

    final userId = FirebaseService.currentUser?.uid;
    final userData = userId == null
        ? null
        : await FirebaseService.getUserData(userId);
    final rawLinks = userData?['links'];
    if (rawLinks is! Map) return const [];
    links = Map<String, dynamic>.from(rawLinks).entries
        .where((entry) => entry.value is Map)
        .map(
          (entry) => LinkModel.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
            id: entry.key,
          ),
        )
        .where((link) => link.categoryId == category.id)
        .toList();
    return links;
  }

  bool get isNearBottom {
    if (!scrollController.hasClients) return true;
    final position = scrollController.position;
    return position.maxScrollExtent - position.pixels < 180;
  }

  void _handleScroll() {
    if (hasNewItemsBelow.value && isNearBottom) {
      hasNewItemsBelow.value = false;
    }
  }

  void scrollToLatest({bool animate = true}) {
    hasNewItemsBelow.value = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed || !scrollController.hasClients) return;
      final target = scrollController.position.maxScrollExtent;
      if (animate) {
        scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        scrollController.jumpTo(target);
      }
    });
  }

  @override
  void onClose() {
    if (FriendController.activeConversationFriendId == friend.friendUserId) {
      FriendController.activeConversationFriendId = null;
    }
    _loadGeneration++;
    _liveReloadDebounce?.cancel();
    _incomingLinksSub?.cancel();
    _incomingCategoriesSub?.cancel();
    _outgoingLinksSub?.cancel();
    _outgoingCategoriesSub?.cancel();
    scrollController.dispose();
    super.onClose();
  }
}

class ShareConversationEntry {
  const ShareConversationEntry._({
    required this.isMine,
    required this.time,
    this.incomingCategory,
    this.incomingLink,
    this.outgoingCategory,
    this.outgoingLink,
  });

  factory ShareConversationEntry.incomingCategory(SharedCategoryModel item) =>
      ShareConversationEntry._(
        isMine: false,
        time: item.sharedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        incomingCategory: item,
      );

  factory ShareConversationEntry.incomingLink(SharedIndividualLinkModel item) =>
      ShareConversationEntry._(
        isMine: false,
        time: item.sharedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        incomingLink: item,
      );

  factory ShareConversationEntry.outgoingCategory(
    CategoryModel item, {
    DateTime? sharedTime,
  }) => ShareConversationEntry._(
    isMine: true,
    time:
        sharedTime ??
        item.updatedAt ??
        item.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0),
    outgoingCategory: item,
  );

  factory ShareConversationEntry.outgoingLink(
    LinkModel item, {
    DateTime? sharedTime,
  }) => ShareConversationEntry._(
    isMine: true,
    time:
        sharedTime ??
        item.updatedAt ??
        item.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0),
    outgoingLink: item,
  );

  final bool isMine;
  final DateTime time;
  final SharedCategoryModel? incomingCategory;
  final SharedIndividualLinkModel? incomingLink;
  final CategoryModel? outgoingCategory;
  final LinkModel? outgoingLink;

  String get identityKey {
    if (incomingCategory != null) {
      return 'in:category:${incomingCategory!.ownerUid}/${incomingCategory!.categoryId}';
    }
    if (incomingLink != null) {
      return 'in:link:${incomingLink!.ownerUid}/${incomingLink!.linkId}';
    }
    if (outgoingCategory != null) {
      return 'out:category:${outgoingCategory!.id}';
    }
    return 'out:link:${outgoingLink?.id ?? ''}';
  }

  bool get isCategory => incomingCategory != null || outgoingCategory != null;
  String get title =>
      incomingCategory?.categoryName ??
      outgoingCategory?.name ??
      incomingLink?.link.name ??
      incomingLink?.link.metaDataModel?.title ??
      outgoingLink?.name ??
      outgoingLink?.metaDataModel?.title ??
      'Link';
  String get imageUrl =>
      incomingLink?.link.metaDataModel?.imageUrl ??
      outgoingLink?.metaDataModel?.imageUrl ??
      '';
  int get categoryCount {
    if (incomingCategory != null) return incomingCategory!.linkCount;
    final categoryId = outgoingCategory?.id;
    return AppCache.links.where((link) => link.categoryId == categoryId).length;
  }

  String get url =>
      incomingLink?.link.metaDataModel?.url ??
      outgoingLink?.metaDataModel?.url ??
      '';
  String get favicon =>
      incomingLink?.link.metaDataModel?.favicon ??
      incomingLink?.link.metaDataModel?.appleIcon ??
      outgoingLink?.metaDataModel?.favicon ??
      outgoingLink?.metaDataModel?.appleIcon ??
      '';
  String get host {
    final uri = Uri.tryParse(url);
    return uri?.host.replaceFirst('www.', '') ?? '';
  }
}
