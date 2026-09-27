import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/image/cache_image.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/presentation/controller/share_conversation_controller.dart';
import 'package:keep_link/features/friend/presentation/page/shared_categories_page.dart';
import 'package:keep_link/features/friend/presentation/widgets/share_link_to_friend_sheet.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/widgets/link_item.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/link_detail_controller.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/page/link_detail.dart';

class ShareConversationPage extends GetView<ShareConversationController> {
  const ShareConversationPage({super.key});

  static const routeName = '/ShareConversationPage';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.bg700,
        appBar: AppBar(
          backgroundColor: AppColors.bg700,
          elevation: 0,
          leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.t200,
              size: 20,
            ),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              SharedOwnerAvatar(
                displayName: controller.friend.displayName,
                photoUrl: controller.friend.photoUrl,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: controller.friend.displayName,
                      color: AppColors.white,
                      size: 15,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                    ),
                    const TextWidget(
                      text: 'Trao đổi link',
                      color: AppColors.n70,
                      size: 10.5,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: const [SizedBox(width: 16)],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _shareButton(context),
        body: Obx(() => _body(context)),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (controller.isLoading.value && controller.items.isEmpty) {
      return const _ConversationLoading();
    }
    if (controller.errorMessage.value != null && controller.items.isEmpty) {
      return _ConversationError(
        message: controller.errorMessage.value!,
        onRetry: () => controller.load(showLoading: true, forceShared: true),
      );
    }
    if (controller.items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.d500,
        onRefresh: controller.refreshConversation,
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [SliverFillRemaining(child: _EmptyConversation())],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.d500,
          onRefresh: controller.refreshConversation,
          child: ListView.builder(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 92),
            itemCount: controller.items.length,
            itemBuilder: (context, index) {
              final entry = controller.items[index];
              final previous = index == 0 ? null : controller.items[index - 1];
              final next = index == controller.items.length - 1
                  ? null
                  : controller.items[index + 1];
              final startsDay =
                  previous == null || !_sameDay(previous.time, entry.time);
              final endsGroup =
                  next == null ||
                  next.isMine != entry.isMine ||
                  !_sameDay(next.time, entry.time) ||
                  next.time.difference(entry.time).abs() >
                      const Duration(minutes: 5);
              return Column(
                children: [
                  if (startsDay) _DaySeparator(value: entry.time),
                  _ShareBubble(
                    key: ValueKey(entry.identityKey),
                    entry: entry,
                    friend: controller.friend,
                    myDisplayName: controller.myDisplayName,
                    myPhotoUrl: controller.myPhotoUrl,
                    showAvatar: endsGroup,
                    endsGroup: endsGroup,
                    onTap: () => _openEntry(context, entry),
                  ),
                ],
              );
            },
          ),
        ),
        if (controller.isRefreshing.value)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: Colors.transparent,
            ),
          ),
        if (controller.hasNewItemsBelow.value)
          Positioned(
            right: 16,
            bottom: 86,
            child: FloatingActionButton.small(
              heroTag: 'latest_share_message',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              onPressed: controller.scrollToLatest,
              child: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ),
      ],
    );
  }

  Widget _shareButton(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryBright],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacityCompat(.38),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final changed = await openShareLinkToFriendSheet(
              context,
              controller.friend,
            );
            if (changed == true) await controller.reloadAfterShare();
          },
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_link_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                TextWidget(
                  text: 'share_link'.tr,
                  color: AppColors.white,
                  size: 14,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEntry(
    BuildContext context,
    ShareConversationEntry entry,
  ) async {
    if (entry.incomingLink != null) {
      await Get.toNamed(
        LinkDetailPage.routeName,
        arguments: LinkDetailArguments(
          link: entry.incomingLink!.link,
          readOnly: true,
        ),
      );
      return;
    }
    if (entry.outgoingLink != null) {
      await Get.toNamed(
        LinkDetailPage.routeName,
        arguments: entry.outgoingLink,
      );
      return;
    }
    if (entry.incomingCategory != null) {
      if (context.mounted) {
        openSharedCategoryLinksSheet(
          context,
          controller.shared,
          entry.incomingCategory!,
        );
      }
      return;
    }
    final category = entry.outgoingCategory;
    if (category == null) return;
    final links = await controller.loadOutgoingCategoryLinks(category);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.modalSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
                child: Row(
                  children: [
                    const Icon(Icons.folder_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextWidget(
                        text: category.name ?? 'Danh mục',
                        color: AppColors.white,
                        size: 17,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                      ),
                    ),
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.n70,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: links.isEmpty
                    ? const Center(
                        child: TextWidget(
                          text: 'Danh mục chưa có link',
                          color: AppColors.n70,
                        ),
                      )
                    : ListView.separated(
                        itemCount: links.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: AppColors.white.withOpacityCompat(.06),
                        ),
                        itemBuilder: (_, index) =>
                            LinkListItem(index: index, item: links[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.value});

  final DateTime value;

  @override
  Widget build(BuildContext context) {
    if (value.millisecondsSinceEpoch == 0) return const SizedBox(height: 8);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(value.year, value.month, value.day);
    final difference = today.difference(day).inDays;
    final label = difference == 0
        ? 'Hôm nay'
        : difference == 1
        ? 'Hôm qua'
        : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextWidget(text: label, color: AppColors.n70, size: 11),
    );
  }
}

class _ShareBubble extends StatelessWidget {
  const _ShareBubble({
    super.key,
    required this.entry,
    required this.friend,
    required this.onTap,
    required this.showAvatar,
    required this.endsGroup,
    this.myDisplayName,
    this.myPhotoUrl,
  });

  final ShareConversationEntry entry;
  final FriendModel friend;
  final VoidCallback onTap;
  final bool showAvatar;
  final bool endsGroup;
  final String? myDisplayName;
  final String? myPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final avatar = SharedOwnerAvatar(
      displayName: entry.isMine ? (myDisplayName ?? 'Me') : friend.displayName,
      photoUrl: entry.isMine ? myPhotoUrl : friend.photoUrl,
      size: 28,
    );
    final imageUrl = entry.imageUrl;
    final emoji = entry.outgoingCategory?.iconUrl?.trim();
    return Padding(
      padding: EdgeInsets.only(
        left: entry.isMine ? 56 : 0,
        right: entry.isMine ? 0 : 56,
        bottom: endsGroup ? 12 : 4,
      ),
      child: Row(
        mainAxisAlignment: entry.isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!entry.isMine) ...[
            SizedBox(width: 28, child: showAvatar ? avatar : null),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Material(
              color: entry.isMine
                  ? AppColors.primary.withOpacityCompat(.22)
                  : AppColors.d500,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(
                  !entry.isMine && endsGroup ? 4 : 16,
                ),
                bottomRight: Radius.circular(
                  entry.isMine && endsGroup ? 4 : 16,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  width: double.infinity,
                  height: 175,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: imageUrl.isNotEmpty
                            ? CacheImageWidget(
                                imageUrl: imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                memCacheWidth: 640,
                                memCacheHeight: 640,
                              )
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary.withOpacityCompat(
                                        entry.isMine ? .35 : .2,
                                      ),
                                      AppColors.navigationSurface,
                                      AppColors.d500,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: entry.isCategory
                                      ? emoji != null && emoji.isNotEmpty
                                            ? TextWidget(text: emoji, size: 36)
                                            : const Icon(
                                                Icons.folder_shared_rounded,
                                                color: AppColors.primaryBright,
                                                size: 40,
                                              )
                                      : const Icon(
                                          Icons.link_rounded,
                                          color: AppColors.primaryBright,
                                          size: 40,
                                        ),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.black.withOpacityCompat(.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                entry.isCategory
                                    ? Icons.folder_rounded
                                    : Icons.language_rounded,
                                size: 12,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 4),
                              TextWidget(
                                text: entry.isCategory
                                    ? '${entry.categoryCount} link'
                                    : entry.host,
                                color: AppColors.white,
                                size: 10,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 26, 10, 8),
                          decoration: BoxDecoration(
                            gradient: AppGradients.bgDarkGradient,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextWidget(
                                text: entry.title,
                                color: AppColors.white,
                                textStyle: AppTextStyle.semiBold14,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextWidget(
                                  text: _time(entry.time),
                                  color: AppColors.white.withOpacityCompat(.7),
                                  size: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (entry.isMine) ...[
            const SizedBox(width: 8),
            SizedBox(width: 28, child: showAvatar ? avatar : null),
          ],
        ],
      ),
    );
  }

  static String _time(DateTime value) {
    if (value.millisecondsSinceEpoch == 0) return '';
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _ConversationLoading extends StatelessWidget {
  const _ConversationLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2.5,
      ),
    );
  }
}

class _ConversationError extends StatelessWidget {
  const _ConversationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.n70, size: 42),
            const SizedBox(height: 12),
            TextWidget(
              text: message,
              color: AppColors.n70,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: TextWidget(
          text: 'Hai bạn chưa chia sẻ link hoặc danh mục nào.',
          color: AppColors.n70,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
