import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/application/di/share_conversation_binding.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';
import 'package:keep_link/features/friend/presentation/page/share_conversation_page.dart';
import 'package:keep_link/features/friend/presentation/page/shared_categories_page.dart';
import 'package:keep_link/features/friend/presentation/widgets/shared_categories_tab.dart';

class ShareConversationsView extends StatefulWidget {
  const ShareConversationsView({
    super.key,
    required this.friendController,
    required this.sharedController,
  });

  final FriendController friendController;
  final SharedCategoryController sharedController;

  @override
  State<ShareConversationsView> createState() => _ShareConversationsViewState();
}

class _ShareConversationsViewState extends State<ShareConversationsView> {
  final Map<String, ({int categories, int links})> _outgoingCounts = {};
  bool _loadingOutgoing = true;
  late final Worker _outgoingShareWorker;

  @override
  void initState() {
    super.initState();
    _outgoingShareWorker = ever<int>(
      widget.sharedController.outgoingRevision,
      (_) => _loadOutgoing(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOutgoing());
  }

  @override
  void dispose() {
    _outgoingShareWorker.dispose();
    super.dispose();
  }

  Future<void> _loadOutgoing() async {
    final friends = List<FriendModel>.from(AppCache.friends);
    final userId = FirebaseService.currentUser?.uid;
    final results = await Future.wait<dynamic>([
      userId == null
          ? Future<Map<String, dynamic>?>.value(null)
          : FirebaseService.getUserData(userId),
      Future.wait(
        friends.map((friend) async {
          final result = await Future.wait([
            FirebaseService.getCategoryIdsSharedWithFriend(friend.friendUserId),
            FirebaseService.getLinkIdsSharedWithFriend(friend.friendUserId),
          ]);
          return MapEntry(friend.friendUserId, (
            categoryIds: result[0],
            linkIds: result[1],
          ));
        }),
      ),
    ]);
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
        ? Map<String, dynamic>.from(userData!['categories'] as Map).keys.toSet()
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
    if (!mounted) return;
    setState(() {
      _outgoingCounts
        ..clear()
        ..addEntries(
          entries.map(
            (entry) => MapEntry(entry.key, (
              categories: entry.value.categoryIds
                  .where(validCategoryIds.contains)
                  .length,
              links: entry.value.linkIds.where(validLinkIds.contains).length,
            )),
          ),
        );
      _loadingOutgoing = false;
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      widget.friendController.fetchFriends(),
      widget.sharedController.loadAllSharedData(force: true),
    ]);
    await _loadOutgoing();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.d500,
      onRefresh: _refresh,
      child: Obx(() {
        final conversations = _buildConversations();
        final isLoading =
            widget.sharedController.isLoading.value || _loadingOutgoing;

        if (isLoading && conversations.isEmpty) {
          return const SharedLoadingView();
        }
        if (widget.sharedController.errorMessage.value != null &&
            conversations.isEmpty) {
          return SharedErrorView(
            message: widget.sharedController.errorMessage.value!,
            onRetry: _refresh,
          );
        }
        if (conversations.isEmpty) return const _EmptyConversations();

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 4, bottom: 32),
          itemCount: conversations.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 1,
            indent: 82,
            color: AppColors.white.withOpacityCompat(.06),
          ),
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _ConversationTile(
              data: conversation,
              onTap: () async {
                await Get.toNamed(
                  ShareConversationPage.routeName,
                  arguments: ShareConversationArguments(
                    friend: conversation.friend,
                  ),
                );
                if (mounted) {
                  await widget.sharedController.loadAllSharedData(force: true);
                  await _loadOutgoing();
                }
              },
            );
          },
        );
      }),
    );
  }

  List<_ConversationData> _buildConversations() {
    final byUid = <String, _ConversationData>{};
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
      final data = byUid.putIfAbsent(uid, () => _ConversationData(friend));
      data.totalItems++;
      if (widget.sharedController.unviewedKeys.contains(key)) {
        data.unreadItems++;
      }
      if (data.latestAt == null ||
          (time != null && time.isAfter(data.latestAt!))) {
        data.latestAt = time;
        data.preview = preview;
      }
    }

    for (final category in widget.sharedController.sharedCategories) {
      addIncoming(
        uid: category.ownerUid,
        name: category.ownerDisplayName,
        photo: category.ownerPhotoUrl,
        time: category.sharedAt,
        preview: 'Đã chia sẻ danh mục “${category.categoryName}”',
        key: '${category.ownerUid}/${category.categoryId}',
      );
    }
    for (final item in widget.sharedController.sharedIndividualLinks) {
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

    for (final entry in _outgoingCounts.entries) {
      final count = entry.value.categories + entry.value.links;
      if (count == 0) continue;
      final friend = friendsByUid[entry.key];
      if (friend == null) continue;
      final data = byUid.putIfAbsent(
        entry.key,
        () => _ConversationData(friend),
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
}

class _ConversationData {
  _ConversationData(this.friend);

  final FriendModel friend;
  String preview = '';
  DateTime? latestAt;
  int unreadItems = 0;
  int totalItems = 0;
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.data, required this.onTap});

  final _ConversationData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SharedOwnerAvatar(
                    displayName: data.friend.displayName,
                    photoUrl: data.friend.photoUrl,
                    size: 50,
                  ),
                  if (data.unreadItems > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AppColors.bg700, width: 2),
                        ),
                        child: TextWidget(
                          text: '${data.unreadItems}',
                          color: AppColors.white,
                          size: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextWidget(
                            text: data.friend.displayName,
                            color: AppColors.white,
                            size: 15,
                            fontWeight: data.unreadItems > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                            maxLines: 1,
                          ),
                        ),
                        if (data.latestAt != null)
                          TextWidget(
                            text: _compactTime(data.latestAt!),
                            color: AppColors.n500,
                            size: 11,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: TextWidget(
                            text: data.preview,
                            color: data.unreadItems > 0
                                ? AppColors.t200
                                : AppColors.n70,
                            size: 12.5,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextWidget(
                          text: '${data.totalItems}',
                          color: AppColors.n500,
                          size: 11,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.n500,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _compactTime(DateTime time) {
    final now = DateTime.now();
    if (now.year == time.year &&
        now.month == time.month &&
        now.day == time.day) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}';
  }
}

class _EmptyConversations extends StatelessWidget {
  const _EmptyConversations();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      color: AppColors.d500,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.forum_outlined,
                      color: AppColors.primary,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const TextWidget(
                    text: 'Chưa có trao đổi link',
                    color: AppColors.white,
                    size: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 7),
                  const TextWidget(
                    text:
                        'Khi bạn và bạn bè chia sẻ link hoặc danh mục, cuộc trò chuyện sẽ xuất hiện tại đây.',
                    color: AppColors.n70,
                    size: 12,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
