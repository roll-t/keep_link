import 'package:get/get.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';

class ShareConversationsController extends GetxController {
  ShareConversationsController({
    required this.friendController,
    required this.sharedController,
  });

  final FriendController friendController;
  final SharedCategoryController sharedController;

  final RxMap<String, OutgoingShareCount> outgoingCounts =
      <String, OutgoingShareCount>{}.obs;
  final RxBool isLoadingOutgoing = true.obs;
  final RxBool isInitialLoading = true.obs;

  Worker? _outgoingShareWorker;
  int _loadGeneration = 0;

  bool get isLoading =>
      sharedController.isLoading.value || isLoadingOutgoing.value;

  String? get errorMessage => sharedController.errorMessage.value;

  List<ShareConversationSummary> get conversations {
    final byUid = <String, ShareConversationSummary>{};
    final friendsByUid = {
      for (final friend in AppCache.friends) friend.friendUserId: friend,
    };

    void addIncoming({
      required String uid,
      required String name,
      required String? photo,
      required DateTime? time,
      required String preview,
      required String key,
    }) {
      final friend =
          friendsByUid[uid] ??
          FriendModel(friendUserId: uid, displayName: name, photoUrl: photo);
      final data = byUid.putIfAbsent(
        uid,
        () => ShareConversationSummary(friend),
      );
      data.totalItems++;
      if (sharedController.unviewedKeys.contains(key)) {
        data.unreadItems++;
      }
      if (data.latestAt == null ||
          (time != null && time.isAfter(data.latestAt!))) {
        data.latestAt = time;
        data.preview = preview;
      }
    }

    for (final category in sharedController.sharedCategories) {
      addIncoming(
        uid: category.ownerUid,
        name: category.ownerDisplayName,
        photo: category.ownerPhotoUrl,
        time: category.sharedAt,
        preview: 'Đã chia sẻ danh mục “${category.categoryName}”',
        key: '${category.ownerUid}/${category.categoryId}',
      );
    }
    for (final item in sharedController.sharedIndividualLinks) {
      final title = item.link.name ?? item.link.metaDataModel?.title ?? 'Link';
      addIncoming(
        uid: item.ownerUid,
        name: item.ownerDisplayName,
        photo: item.ownerPhotoUrl,
        time: item.sharedAt,
        preview: 'Đã gửi “$title”',
        key: '${item.ownerUid}/${item.linkId}',
      );
    }

    for (final entry in outgoingCounts.entries) {
      final count = entry.value.categories + entry.value.links;
      if (count == 0) continue;
      final friend = friendsByUid[entry.key];
      if (friend == null) continue;
      final data = byUid.putIfAbsent(
        entry.key,
        () => ShareConversationSummary(friend),
      );
      data.totalItems += count;
      if (data.preview.isEmpty) {
        data.preview = 'Bạn đã chia sẻ $count mục';
      }
    }

    return byUid.values.toList()..sort((a, b) {
      final aTime = a.latestAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.latestAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  @override
  void onInit() {
    super.onInit();
    _outgoingShareWorker = ever<int>(
      sharedController.outgoingRevision,
      (_) => loadOutgoing(),
    );
  }

  @override
  void onReady() {
    super.onReady();
    _loadInitialConversations();
  }

  Future<void> _loadInitialConversations() async {
    isInitialLoading.value = true;
    try {
      await Future.wait([sharedController.loadAllSharedData(), loadOutgoing()]);
    } finally {
      if (!isClosed) isInitialLoading.value = false;
    }
  }

  Future<void> refreshConversations() async {
    await Future.wait([
      friendController.fetchFriends(),
      sharedController.loadAllSharedData(force: true),
    ]);
    await loadOutgoing();
  }

  Future<void> reloadAfterConversation() async {
    if (isClosed) return;
    await sharedController.loadAllSharedData(force: true);
    await loadOutgoing();
  }

  Future<void> loadOutgoing() async {
    final generation = ++_loadGeneration;
    isLoadingOutgoing.value = true;

    try {
      final friends = List<FriendModel>.from(AppCache.friends);
      final userId = FirebaseService.currentUser?.uid;
      final results = await Future.wait<dynamic>([
        userId == null
            ? Future<Map<String, dynamic>?>.value(null)
            : FirebaseService.getUserData(userId),
        Future.wait(
          friends.map((friend) async {
            final result = await Future.wait([
              FirebaseService.getCategoryIdsSharedWithFriend(
                friend.friendUserId,
              ),
              FirebaseService.getLinkIdsSharedWithFriend(friend.friendUserId),
            ]);
            return MapEntry(friend.friendUserId, (
              categoryIds: result[0],
              linkIds: result[1],
            ));
          }),
        ),
      ]);
      if (generation != _loadGeneration || isClosed) return;

      final userData = results[0] as Map<String, dynamic>?;
      final entries =
          results[1]
              as List<
                MapEntry<
                  String,
                  ({List<String> categoryIds, List<String> linkIds})
                >
              >;
      final remoteCategoryIds = userData?['categories'] is Map
          ? Map<String, dynamic>.from(
              userData!['categories'] as Map,
            ).keys.toSet()
          : <String>{};
      final remoteLinkIds = userData?['links'] is Map
          ? Map<String, dynamic>.from(userData!['links'] as Map).keys.toSet()
          : <String>{};
      final validCategoryIds = {
        ...remoteCategoryIds,
        ...AppCache.categories.map((item) => item.id).whereType<String>(),
      };
      final validLinkIds = {
        ...remoteLinkIds,
        ...AppCache.links.map((item) => item.id),
      };

      outgoingCounts.assignAll({
        for (final entry in entries)
          entry.key: OutgoingShareCount(
            categories: entry.value.categoryIds
                .where(validCategoryIds.contains)
                .length,
            links: entry.value.linkIds.where(validLinkIds.contains).length,
          ),
      });
    } finally {
      if (generation == _loadGeneration && !isClosed) {
        isLoadingOutgoing.value = false;
      }
    }
  }

  @override
  void onClose() {
    _loadGeneration++;
    _outgoingShareWorker?.dispose();
    super.onClose();
  }
}

class OutgoingShareCount {
  const OutgoingShareCount({required this.categories, required this.links});

  final int categories;
  final int links;
}

class ShareConversationSummary {
  ShareConversationSummary(this.friend);

  final FriendModel friend;
  String preview = '';
  DateTime? latestAt;
  int unreadItems = 0;
  int totalItems = 0;
}
