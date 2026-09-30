import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/data/repositories/category_repository.dart';
import 'package:keep_link/core/data/repositories/link_repository.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/core/utils/link_source_util.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/application/model/shared_category_model.dart';
import 'package:keep_link/features/friend/application/model/shared_individual_link_model.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

enum ShareSortOption { newest, oldest }
enum ShareSenderFilter { all, mine, friend }
enum ShareTypeFilter { all, link, category }

class ShareConversationController extends GetxController {
  ShareConversationController({required this.friend});

  static const int _pageSize = 12;
  static const double _loadOlderThreshold = 240;

  final FriendModel friend;
  final SharedCategoryController shared = Get.find<SharedCategoryController>();
  final ScrollController scrollController = ScrollController();

  final RxList<ShareConversationEntry> items = <ShareConversationEntry>[].obs;
  final RxMap<String, String> reactions = <String, String>{}.obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoadingOlder = false.obs;
  final RxBool hasMoreOlder = false.obs;
  final RxBool hasNewItemsBelow = false.obs;
  final RxBool isDeleting = false.obs;
  final RxnString errorMessage = RxnString();

  // Search & Filter
  final TextEditingController searchTec = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final RxString searchText = ''.obs;
  final RxBool isSearching = false.obs;

  final Rx<ShareSortOption> selectedSort = ShareSortOption.newest.obs;
  final Rx<ShareSenderFilter> selectedSender = ShareSenderFilter.all.obs;
  final Rx<ShareTypeFilter> selectedType = ShareTypeFilter.all.obs;
  final RxnString selectedSource = RxnString();
  final RxList<SourceStat> availableSources = <SourceStat>[].obs;

  int get activeFilterCount =>
      (selectedSender.value != ShareSenderFilter.all ? 1 : 0) +
      (selectedType.value != ShareTypeFilter.all ? 1 : 0) +
      (selectedSource.value != null ? 1 : 0) +
      (selectedSort.value != ShareSortOption.newest ? 1 : 0);

  bool get hasActiveFilters => activeFilterCount > 0;

  String get senderLabel {
    switch (selectedSender.value) {
      case ShareSenderFilter.mine:
        return 'Tôi gửi';
      case ShareSenderFilter.friend:
        return friend.displayName.isNotEmpty ? friend.displayName : 'Bạn bè';
      case ShareSenderFilter.all:
        return 'Tất cả';
    }
  }

  String get typeLabel {
    switch (selectedType.value) {
      case ShareTypeFilter.link:
        return 'Link';
      case ShareTypeFilter.category:
        return 'Danh mục';
      case ShareTypeFilter.all:
        return 'Tất cả';
    }
  }

  String get sortLabel {
    switch (selectedSort.value) {
      case ShareSortOption.newest:
        return 'Mới nhất';
      case ShareSortOption.oldest:
        return 'Cũ nhất';
    }
  }

  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (isSearching.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!searchFocusNode.hasFocus) {
          searchFocusNode.requestFocus();
        }
      });
    } else {
      clearSearch();
    }
  }

  void clearSearch() {
    searchTec.clear();
    searchText.value = '';
    _applyFilterAndSearch();
  }

  void _handleSearchFocusChange() {
    if (!searchFocusNode.hasFocus && isSearching.value && searchTec.text.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!searchFocusNode.hasFocus && isSearching.value && searchTec.text.trim().isEmpty) {
          closeSearch();
        }
      });
    }
  }

  void closeSearch() {
    isSearching.value = false;
    searchFocusNode.unfocus();
    clearSearch();
  }

  void selectSort(ShareSortOption sort) {
    selectedSort.value = sort;
    _applyFilterAndSearch();
  }

  void selectSender(ShareSenderFilter sender) {
    selectedSender.value = sender;
    _applyFilterAndSearch();
  }

  void selectType(ShareTypeFilter type) {
    selectedType.value = type;
    _applyFilterAndSearch();
  }

  void selectSource(String? source) {
    selectedSource.value = source;
    _applyFilterAndSearch();
  }

  void resetFilters() {
    selectedSender.value = ShareSenderFilter.all;
    selectedType.value = ShareTypeFilter.all;
    selectedSource.value = null;
    selectedSort.value = ShareSortOption.newest;
    _applyFilterAndSearch();
  }

  void clearAllFiltersAndSearch() {
    clearSearch();
    resetFilters();
  }

  List<ShareConversationEntry> get filteredAllItems => _getFilteredItems();

  List<ShareConversationEntry> _getFilteredItems() {
    var list = _allItems;

    // 1. Search text
    final query = searchText.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((entry) {
        final title = entry.title.toLowerCase();
        final url = entry.url.toLowerCase();
        final host = entry.host.toLowerCase();
        return title.contains(query) || url.contains(query) || host.contains(query);
      }).toList();
    }

    // 2. Sender
    if (selectedSender.value == ShareSenderFilter.mine) {
      list = list.where((entry) => entry.isMine).toList();
    } else if (selectedSender.value == ShareSenderFilter.friend) {
      list = list.where((entry) => !entry.isMine).toList();
    }

    // 3. Type
    if (selectedType.value == ShareTypeFilter.link) {
      list = list.where((entry) => !entry.isCategory).toList();
    } else if (selectedType.value == ShareTypeFilter.category) {
      list = list.where((entry) => entry.isCategory).toList();
    }

    // 4. Source
    final source = selectedSource.value;
    if (source != null && source.isNotEmpty) {
      list = list.where((entry) {
        final entryHost = LinkSourceUtil.normalizeHost(entry.url);
        return entryHost == source || entry.host.toLowerCase().contains(source.toLowerCase());
      }).toList();
    }

    // 5. Sort
    if (selectedSort.value == ShareSortOption.oldest) {
      list = list.toList()..sort((a, b) => a.time.compareTo(b.time));
    } else {
      list = list.toList()..sort((a, b) => b.time.compareTo(a.time));
    }

    return list;
  }

  void _applyFilterAndSearch() {
    final filtered = _getFilteredItems();
    items.assignAll(filtered.take(_pageSize));
    hasMoreOlder.value = items.length < filtered.length;
  }

  void _updateAvailableSources() {
    final counter = <String, int>{};
    for (final entry in _allItems) {
      final host = LinkSourceUtil.normalizeHost(entry.url);
      if (host.isEmpty) continue;
      counter[host] = (counter[host] ?? 0) + 1;
    }
    final sorted = counter.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    availableSources.assignAll(
      sorted.map(
        (e) => SourceStat(
          host: e.key,
          label: LinkSourceUtil.labelForHost(e.key),
          count: e.value,
        ),
      ),
    );
  }

  String? getReaction(String identityKey) {
    return reactions[identityKey] ??
        AppGetStorage.getMessageReaction(identityKey);
  }

  void toggleReaction(String identityKey, String emoji) {
    final current = getReaction(identityKey);
    if (current == emoji) {
      reactions.remove(identityKey);
      AppGetStorage.setMessageReaction(identityKey, null);
    } else {
      reactions[identityKey] = emoji;
      AppGetStorage.setMessageReaction(identityKey, emoji);
    }
  }

  List<ShareConversationEntry> _allItems = const [];

  Timer? _liveReloadDebounce;
  StreamSubscription? _incomingLinksSub;
  StreamSubscription? _incomingCategoriesSub;
  StreamSubscription? _outgoingLinksSub;
  StreamSubscription? _outgoingCategoriesSub;
  StreamSubscription? _shareEventsSub;
  Future<void>? _loadFuture;
  int _loadGeneration = 0;
  bool _hasCompletedInitialLoad = false;
  bool _reloadQueued = false;
  bool _queuedForceShared = false;
  bool _deferRealtimeReload = false;
  bool _hasDeferredRealtimeChange = false;

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
    searchTec.addListener(() {
      searchText.value = searchTec.text;
    });
    searchFocusNode.addListener(_handleSearchFocusChange);
    debounce(
      searchText,
      (_) => _applyFilterAndSearch(),
      time: const Duration(milliseconds: 250),
    );
    _startRealtimeWatchers();
  }

  @override
  void onReady() {
    super.onReady();
    load(showLoading: true, forceShared: true);
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
    _shareEventsSub = FirebaseService.watchShareEventsWithFriend(
      friendId,
    ).skip(1).listen((_) => _onRealtimeChange(), onError: (_) {});
  }

  void _onRealtimeChange() {
    if (_deferRealtimeReload) {
      _hasDeferredRealtimeChange = true;
      return;
    }
    _liveReloadDebounce?.cancel();
    _liveReloadDebounce = Timer(const Duration(milliseconds: 300), () {
      SharedCategoryController.invalidateCache();
      load(forceShared: true);
    });
  }

  void beginShareSelection() {
    _deferRealtimeReload = true;
    if (_liveReloadDebounce?.isActive ?? false) {
      _hasDeferredRealtimeChange = true;
      _liveReloadDebounce?.cancel();
    }
  }

  Future<void> endShareSelection({required bool changed}) async {
    _deferRealtimeReload = false;
    final shouldReload = changed || _hasDeferredRealtimeChange;
    _hasDeferredRealtimeChange = false;
    if (!shouldReload || isClosed) return;
    SharedCategoryController.invalidateCache();
    await load(forceShared: true);
  }

  Future<void> refreshConversation() => load(forceShared: true);

  Future<void> load({
    bool showLoading = false,
    bool forceShared = false,
  }) async {
    final pending = _loadFuture;
    if (pending != null) {
      _reloadQueued = true;
      _queuedForceShared = _queuedForceShared || forceShared;
      await pending;
      return;
    }

    final generation = ++_loadGeneration;
    final wasNearBottom = isNearBottom;
    final previousPixels = scrollController.hasClients
        ? scrollController.position.pixels
        : null;
    final previousMaxScrollExtent = scrollController.hasClients
        ? scrollController.position.maxScrollExtent
        : null;
    final previousKeys = _allItems.map((item) => item.identityKey).toSet();
    final future = _performLoad(
      generation: generation,
      showLoading: showLoading,
      forceShared: forceShared,
      wasNearBottom: wasNearBottom,
      previousPixels: previousPixels,
      previousMaxScrollExtent: previousMaxScrollExtent,
      previousKeys: previousKeys,
    );
    _loadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_loadFuture, future)) _loadFuture = null;
      if (_reloadQueued && !isClosed) {
        final queuedForce = _queuedForceShared;
        _reloadQueued = false;
        _queuedForceShared = false;
        unawaited(load(forceShared: queuedForce));
      }
    }
  }

  Future<void> _performLoad({
    required int generation,
    required bool showLoading,
    required bool forceShared,
    required bool wasNearBottom,
    required double? previousPixels,
    required double? previousMaxScrollExtent,
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
        FirebaseService.getShareEventsWithFriend(friend.friendUserId),
      ]);
      final nextItems = await _composeItems(outgoing);
      if (generation != _loadGeneration || isClosed) return;

      final hasNewItem = nextItems.any(
        (item) => !previousKeys.contains(item.identityKey),
      );
      _allItems = nextItems;
      _updateAvailableSources();
      final filtered = _getFilteredItems();
      final isInitialLoad = !_hasCompletedInitialLoad;
      final visibleCount = isInitialLoad
          ? _pageSize
          : (items.length < _pageSize ? _pageSize : items.length);
      items.assignAll(filtered.take(visibleCount));
      hasMoreOlder.value = items.length < filtered.length;
      _hasCompletedInitialLoad = true;

      if (!isInitialLoad &&
          !wasNearBottom &&
          previousPixels != null &&
          previousMaxScrollExtent != null) {
        _restoreViewportAfterReload(
          previousPixels: previousPixels,
          previousMaxScrollExtent: previousMaxScrollExtent,
        );
      }

      if (!isInitialLoad && hasNewItem && !wasNearBottom) {
        hasNewItemsBelow.value = true;
      } else if (wasNearBottom) {
        hasNewItemsBelow.value = false;
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
    final categoryIds = (outgoing[0] as List<String>).toSet();
    final linkIds = (outgoing[1] as List<String>).toSet();
    final shareTimes = outgoing[2] as Map<String, int>;
    final shareEvents = outgoing[3] as List<ShareEventModel>;
    final currentUserId = FirebaseService.currentUser?.uid;
    final outgoingLinkEvents = <String, List<ShareEventModel>>{};
    final incomingLinkEvents = <String, List<ShareEventModel>>{};
    final outgoingCategoryEvents = <String, List<ShareEventModel>>{};
    final incomingCategoryEvents = <String, List<ShareEventModel>>{};
    for (final event in shareEvents) {
      final isMine = event.senderUid == currentUserId;
      final eventsByItem = event.type == 'category'
          ? (isMine ? outgoingCategoryEvents : incomingCategoryEvents)
          : (isMine ? outgoingLinkEvents : incomingLinkEvents);
      eventsByItem.putIfAbsent(event.itemId, () => []).add(event);
    }

    for (final category in shared.sharedCategories.where(
      (item) => item.ownerUid == friend.friendUserId,
    )) {
      shared.markCategoryViewed(category);
      final events = incomingCategoryEvents[category.categoryId];
      if (events == null || events.isEmpty) {
        result.add(ShareConversationEntry.incomingCategory(category));
      } else {
        result.addAll(
          events.map(
            (event) => ShareConversationEntry.incomingCategory(
              category,
              eventId: event.id,
              sharedTime: event.sharedAt,
            ),
          ),
        );
      }
    }
    for (final item in shared.sharedIndividualLinks.where(
      (item) => item.ownerUid == friend.friendUserId,
    )) {
      shared.markLinkViewed(item);
      final events = incomingLinkEvents[item.linkId];
      if (events == null || events.isEmpty) {
        result.add(ShareConversationEntry.incomingLink(item));
      } else {
        result.addAll(
          events.map(
            (event) => ShareConversationEntry.incomingLink(
              item,
              eventId: event.id,
              sharedTime: event.sharedAt,
            ),
          ),
        );
      }
    }

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
      final events = outgoingCategoryEvents[categoryId];
      final local = AppCache.categories.firstWhereOrNull(
        (category) => category.id == categoryId,
      );
      if (local != null) {
        _addOutgoingCategoryEntries(
          result: result,
          category: local,
          legacySharedTime: sharedTime,
          events: events,
        );
        continue;
      }
      await ensureRemoteContent();
      final raw = remoteCategories![categoryId];
      if (raw is Map) {
        final json = Map<String, dynamic>.from(raw)..['id'] = categoryId;
        _addOutgoingCategoryEntries(
          result: result,
          category: CategoryModel.fromJson(json),
          legacySharedTime: sharedTime,
          events: events,
        );
      }
    }

    for (final linkId in linkIds) {
      final sharedTime = _shareTime(linkId, shareTimes);
      final events = outgoingLinkEvents[linkId];
      final local = AppCache.links.firstWhereOrNull(
        (link) => link.id == linkId,
      );
      if (local != null) {
        _addOutgoingLinkEntries(
          result: result,
          link: local,
          legacySharedTime: sharedTime,
          events: events,
        );
        continue;
      }
      await ensureRemoteContent();
      final raw = remoteLinks![linkId];
      if (raw is Map) {
        _addOutgoingLinkEntries(
          result: result,
          link: LinkModel.fromJson(Map<String, dynamic>.from(raw), id: linkId),
          legacySharedTime: sharedTime,
          events: events,
        );
      }
    }

    result.sort((a, b) => b.time.compareTo(a.time));
    return result;
  }

  void _addOutgoingCategoryEntries({
    required List<ShareConversationEntry> result,
    required CategoryModel category,
    required DateTime? legacySharedTime,
    required List<ShareEventModel>? events,
  }) {
    if (events == null || events.isEmpty) {
      result.add(
        ShareConversationEntry.outgoingCategory(
          category,
          sharedTime: legacySharedTime,
        ),
      );
      return;
    }
    result.addAll(
      events.map(
        (event) => ShareConversationEntry.outgoingCategory(
          category,
          eventId: event.id,
          sharedTime: event.sharedAt,
        ),
      ),
    );
  }

  void _addOutgoingLinkEntries({
    required List<ShareConversationEntry> result,
    required LinkModel link,
    required DateTime? legacySharedTime,
    required List<ShareEventModel>? events,
  }) {
    if (events == null || events.isEmpty) {
      result.add(
        ShareConversationEntry.outgoingLink(link, sharedTime: legacySharedTime),
      );
      return;
    }
    result.addAll(
      events.map(
        (event) => ShareConversationEntry.outgoingLink(
          link,
          eventId: event.id,
          sharedTime: event.sharedAt,
        ),
      ),
    );
  }

  void loadOlder() {
    if (isLoadingOlder.value || !hasMoreOlder.value || isClosed) return;
    isLoadingOlder.value = true;

    final currentFiltered = _getFilteredItems();
    final olderItems = currentFiltered.skip(items.length).take(_pageSize).toList();
    if (olderItems.isNotEmpty) {
      items.addAll(olderItems);
    }
    hasMoreOlder.value = items.length < currentFiltered.length;
    isLoadingOlder.value = false;
  }

  void _restoreViewportAfterReload({
    required double previousPixels,
    required double previousMaxScrollExtent,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed || !scrollController.hasClients) return;
      final position = scrollController.position;
      final extentDelta = position.maxScrollExtent - previousMaxScrollExtent;
      final target = (previousPixels + extentDelta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      position.jumpTo(target);
    });
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

  Future<bool> deleteEntry(ShareConversationEntry entry) async {
    if (isDeleting.value) return false;
    isDeleting.value = true;
    try {
      if (entry.eventId != null) {
        final removedFinalEvent = await FirebaseService.deleteShareEvent(
          friendUid: friend.friendUserId,
          itemId: entry.itemId,
          type: entry.isCategory ? 'category' : 'link',
          eventId: entry.eventId!,
          isMine: entry.isMine,
        );
        if (removedFinalEvent && entry.isMine && entry.isCategory) {
          AppCache.removeSharedFriend(entry.itemId, friend.friendUserId);
        }
      } else if (entry.isMine) {
        if (entry.outgoingLink != null) {
          await FirebaseService.unshareLink(
            friendUid: friend.friendUserId,
            linkId: entry.itemId,
          );
        } else {
          await FirebaseService.unshareCategory(
            friendUid: friend.friendUserId,
            categoryId: entry.itemId,
          );
          AppCache.removeSharedFriend(entry.itemId, friend.friendUserId);
        }
      } else {
        await FirebaseService.deleteIncomingShareForMe(
          friendUid: friend.friendUserId,
          itemId: entry.itemId,
          isCategory: entry.isCategory,
        );
      }

      SharedCategoryController.invalidateCache();
      await load(forceShared: true);
      if (Get.isRegistered<SharedCategoryController>()) {
        shared.notifyOutgoingSharesChanged();
      }
      AppToast.success('delete_message_success'.tr);
      return true;
    } catch (error) {
      debugPrint('Delete share conversation entry error: $error');
      AppToast.error('delete_message_failed'.tr);
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  bool get isNearBottom {
    if (!scrollController.hasClients) return true;
    return scrollController.position.pixels < 180;
  }

  void _handleScroll() {
    if (hasNewItemsBelow.value && isNearBottom) {
      hasNewItemsBelow.value = false;
    }
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (position.maxScrollExtent - position.pixels < _loadOlderThreshold) {
      loadOlder();
    }
  }

  void scrollToLatest({bool animate = true}) {
    hasNewItemsBelow.value = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed || !scrollController.hasClients) return;
      const target = 0.0;
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
    _shareEventsSub?.cancel();
    scrollController.dispose();
    searchFocusNode.removeListener(_handleSearchFocusChange);
    searchTec.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }
}

class ShareConversationEntry {
  const ShareConversationEntry._({
    required this.isMine,
    required this.time,
    this.eventId,
    this.incomingCategory,
    this.incomingLink,
    this.outgoingCategory,
    this.outgoingLink,
  });

  factory ShareConversationEntry.incomingCategory(
    SharedCategoryModel item, {
    String? eventId,
    DateTime? sharedTime,
  }) => ShareConversationEntry._(
    isMine: false,
    time: sharedTime ?? item.sharedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    eventId: eventId,
    incomingCategory: item,
  );

  factory ShareConversationEntry.incomingLink(
    SharedIndividualLinkModel item, {
    String? eventId,
    DateTime? sharedTime,
  }) => ShareConversationEntry._(
    isMine: false,
    time: sharedTime ?? item.sharedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    eventId: eventId,
    incomingLink: item,
  );

  factory ShareConversationEntry.outgoingCategory(
    CategoryModel item, {
    String? eventId,
    DateTime? sharedTime,
  }) => ShareConversationEntry._(
    isMine: true,
    time:
        sharedTime ??
        item.updatedAt ??
        item.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0),
    eventId: eventId,
    outgoingCategory: item,
  );

  factory ShareConversationEntry.outgoingLink(
    LinkModel item, {
    String? eventId,
    DateTime? sharedTime,
  }) => ShareConversationEntry._(
    isMine: true,
    time:
        sharedTime ??
        item.updatedAt ??
        item.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0),
    eventId: eventId,
    outgoingLink: item,
  );

  final bool isMine;
  final DateTime time;
  final String? eventId;
  final SharedCategoryModel? incomingCategory;
  final SharedIndividualLinkModel? incomingLink;
  final CategoryModel? outgoingCategory;
  final LinkModel? outgoingLink;

  String get identityKey {
    if (eventId != null) return 'event:$eventId';
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
  String get itemId =>
      incomingCategory?.categoryId ??
      outgoingCategory?.id ??
      incomingLink?.linkId ??
      outgoingLink?.id ??
      '';
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
