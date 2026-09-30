import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/image/cache_image.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/presentation/widgets/text_field/search_input_field.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/core/utils/link_launcher_util.dart';
import 'package:keep_link/core/utils/link_source_util.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/presentation/controller/share_conversation_controller.dart';
import 'package:keep_link/features/friend/presentation/page/shared_categories_page.dart';
import 'package:keep_link/features/friend/presentation/widgets/messenger_message_menu.dart';
import 'package:keep_link/features/friend/presentation/widgets/share_link_to_friend_sheet.dart';
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Obx(() => _buildAppBar(context)),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Obx(() {
          if (controller.isSearching.value) return const SizedBox.shrink();
          return _shareButton(context);
        }),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (controller.searchFocusNode.hasFocus) {
              controller.searchFocusNode.unfocus();
            }
          },
          child: Column(
            children: [
              Obx(() => _buildActiveFilterBar(context)),
              Expanded(child: Obx(() => _body(context))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    if (controller.isSearching.value) {
      final _ = controller.searchText.value;
      return AppBar(
        backgroundColor: AppColors.d500,
        elevation: 0,
        leading: IconButton(
          onPressed: controller.closeSearch,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.t200, size: 20),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SearchInputField(
            controller: controller.searchTec,
            focusNode: controller.searchFocusNode,
            autoFocus: true,
            hintText: 'Tìm kiếm link trong cuộc trò chuyện...'.tr,
            backgroundColor: AppColors.navigationSurface,
            borderRadius: 20,
            onSubmitted: (_) => controller.searchFocusNode.unfocus(),
            onClear: controller.clearSearch,
          ),
        ),
        actions: [_filterButton(context), const SizedBox(width: 8)],
      );
    }

    return AppBar(
      backgroundColor: AppColors.d500,
      elevation: 0,
      leading: IconButton(
        onPressed: Get.back,
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.t200, size: 20),
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
                const TextWidget(text: 'Trao đổi link', color: AppColors.n70, size: 10.5),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: controller.toggleSearch,
          icon: const Icon(Icons.search_rounded, color: AppColors.t200, size: 22),
        ),
        _filterButton(context),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _filterButton(BuildContext context) {
    final count = controller.activeFilterCount;
    return GestureDetector(
      onTap: () => _showFilterSheet(context, controller),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.tune_rounded,
                key: ValueKey(count > 0),
                color: count > 0 ? AppColors.primaryDim : AppColors.t200,
                size: 22,
              ),
            ),
            Positioned(
              top: -3,
              right: -5,
              child: AnimatedScale(
                scale: count > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        '$count',
                        key: ValueKey('$count'),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterBar(BuildContext context) {
    final hasFilters = controller.hasActiveFilters;
    final hasSearch = controller.searchText.value.isNotEmpty;
    final isVisible = hasFilters || hasSearch;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      child: !isVisible
          ? const SizedBox(width: double.infinity, height: 0)
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: AppColors.surfaceContainerLow,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (hasSearch)
                      _activeFilterChip(
                        key: const ValueKey('chip_search'),
                        icon: Icons.search_rounded,
                        label: '"${controller.searchText.value}"',
                        onDeleted: controller.clearSearch,
                      ),
                    if (controller.selectedSender.value != ShareSenderFilter.all)
                      _activeFilterChip(
                        key: const ValueKey('chip_sender'),
                        icon: Icons.person_outline_rounded,
                        label: controller.senderLabel,
                        onDeleted: () => controller.selectSender(ShareSenderFilter.all),
                      ),
                    if (controller.selectedType.value != ShareTypeFilter.all)
                      _activeFilterChip(
                        key: const ValueKey('chip_type'),
                        icon: Icons.category_outlined,
                        label: controller.typeLabel,
                        onDeleted: () => controller.selectType(ShareTypeFilter.all),
                      ),
                    if (controller.selectedSource.value != null)
                      _activeFilterChip(
                        key: const ValueKey('chip_source'),
                        icon: Icons.public_rounded,
                        label: LinkSourceUtil.labelForHost(controller.selectedSource.value!),
                        onDeleted: () => controller.selectSource(null),
                      ),
                    if (controller.selectedSort.value != ShareSortOption.newest)
                      _activeFilterChip(
                        key: const ValueKey('chip_sort'),
                        icon: Icons.swap_vert_rounded,
                        label: controller.sortLabel,
                        onDeleted: () => controller.selectSort(ShareSortOption.newest),
                      ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: controller.clearAllFiltersAndSearch,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: TextWidget(
                          text: 'Xóa lọc'.tr,
                          color: AppColors.error,
                          size: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _activeFilterChip({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback onDeleted,
  }) {
    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacityCompat(0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacityCompat(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.primaryDim),
            const SizedBox(width: 5),
            TextWidget(text: label, size: 12, fontWeight: FontWeight.w500, color: AppColors.white),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDeleted,
              child: const Icon(Icons.close_rounded, size: 14, color: AppColors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    Widget child;
    if (controller.isLoading.value && controller.items.isEmpty) {
      child = const _ConversationLoading(key: ValueKey('loading'));
    } else if (controller.errorMessage.value != null && controller.items.isEmpty) {
      child = _ConversationError(
        key: const ValueKey('error'),
        message: controller.errorMessage.value!,
        onRetry: () => controller.load(showLoading: true, forceShared: true),
      );
    } else if (controller.items.isEmpty) {
      if (controller.hasActiveFilters || controller.searchText.value.isNotEmpty) {
        child = _EmptyFilteredResult(
          key: const ValueKey('empty_filtered'),
          controller: controller,
        );
      } else {
        child = RefreshIndicator(
          key: const ValueKey('empty_conversation'),
          color: AppColors.primary,
          backgroundColor: AppColors.d500,
          onRefresh: controller.refreshConversation,
          child: const CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [SliverFillRemaining(child: _EmptyConversation())],
          ),
        );
      }
    } else {
      child = Stack(
        key: const ValueKey('conversation_items'),
        children: [
        RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.d500,
          onRefresh: controller.refreshConversation,
          child: ListView.builder(
            controller: controller.scrollController,
            reverse: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 92),
            itemCount: controller.items.length + (controller.hasMoreOlder.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == controller.items.length) {
                return _OlderItemsLoader(isLoading: controller.isLoadingOlder.value);
              }
              final entry = controller.items[index];
              final newer = index == 0 ? null : controller.items[index - 1];
              final older = index == controller.items.length - 1
                  ? null
                  : controller.items[index + 1];
              final startsDay = older == null || !_sameDay(older.time, entry.time);
              final endsGroup =
                  newer == null ||
                  newer.isMine != entry.isMine ||
                  !_sameDay(newer.time, entry.time) ||
                  newer.time.difference(entry.time).abs() > const Duration(minutes: 5);
              return Column(
                children: [
                  if (startsDay) _DaySeparator(value: entry.time),
                  Obx(() {
                    final reaction = controller.getReaction(entry.identityKey);
                    return _ShareBubble(
                      key: ValueKey(entry.identityKey),
                      entry: entry,
                      friend: controller.friend,
                      myDisplayName: controller.myDisplayName,
                      myPhotoUrl: controller.myPhotoUrl,
                      showAvatar: endsGroup,
                      endsGroup: endsGroup,
                      reaction: reaction,
                      onReactionTap: () {
                        HapticFeedback.lightImpact();
                        controller.toggleReaction(entry.identityKey, reaction!);
                      },
                      onTap: () => _openEntry(context, entry),
                      onLongPressWithRect: (rect) =>
                          _showMessengerMenu(context, entry, rect, endsGroup),
                    );
                  }),
                ],
              );
            },
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: child,
    );
  }

  Widget _shareButton(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryBright]),
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
            var changed = false;
            controller.beginShareSelection();
            try {
              changed = await openShareLinkToFriendSheet(context, controller.friend) == true;
            } finally {
              await controller.endShareSelection(changed: changed);
            }
          },
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_link_rounded, color: AppColors.white, size: 20),
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

  Future<void> _openEntry(BuildContext context, ShareConversationEntry entry) async {
    if (entry.incomingLink != null) {
      await Get.toNamed(
        LinkDetailPage.routeName,
        arguments: LinkDetailArguments(link: entry.incomingLink!.link, readOnly: true),
      );
      return;
    }
    if (entry.outgoingLink != null) {
      await Get.toNamed(LinkDetailPage.routeName, arguments: entry.outgoingLink);
      return;
    }
    if (entry.incomingCategory != null) {
      if (context.mounted) {
        openSharedCategoryLinksSheet(context, controller.shared, entry.incomingCategory!);
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
      builder: (_) => CategoryLinksBottomSheet(title: category.name ?? 'Danh mục', links: links),
    );
  }

  Future<void> _showMessengerMenu(
    BuildContext context,
    ShareConversationEntry entry,
    Rect targetRect,
    bool endsGroup,
  ) async {
    final currentReaction = controller.getReaction(entry.identityKey);
    await showMessengerMessageMenu(
      context: context,
      entry: entry,
      targetRect: targetRect,
      currentReaction: currentReaction,
      bubbleWidget: _BubbleCardContent(entry: entry, endsGroup: endsGroup),
      onReactionSelected: (emoji) {
        controller.toggleReaction(entry.identityKey, emoji);
      },
      onCopy: () async {
        final textToCopy = entry.url.isNotEmpty ? entry.url : entry.title;
        await Clipboard.setData(ClipboardData(text: textToCopy));
        AppToast.success(entry.url.isNotEmpty ? 'copied_link'.tr : 'copied_content'.tr);
      },
      onOpen: () async {
        if (entry.url.isNotEmpty) {
          await LinkLauncherUtil.openUrl(entry.url);
        } else {
          _openEntry(context, entry);
        }
      },
      onDelete: () async {
        await controller.deleteEntry(entry);
      },
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
    required this.onLongPressWithRect,
    required this.showAvatar,
    required this.endsGroup,
    this.myDisplayName,
    this.myPhotoUrl,
    this.reaction,
    this.onReactionTap,
  });

  final ShareConversationEntry entry;
  final FriendModel friend;
  final VoidCallback onTap;
  final ValueChanged<Rect> onLongPressWithRect;
  final bool showAvatar;
  final bool endsGroup;
  final String? myDisplayName;
  final String? myPhotoUrl;
  final String? reaction;
  final VoidCallback? onReactionTap;

  @override
  Widget build(BuildContext context) {
    final avatar = SharedOwnerAvatar(
      displayName: entry.isMine ? (myDisplayName ?? 'Me') : friend.displayName,
      photoUrl: entry.isMine ? myPhotoUrl : friend.photoUrl,
      size: 28,
    );
    final bool hasReaction = reaction != null && reaction!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: entry.isMine ? 56 : 0,
        right: entry.isMine ? 0 : 56,
        bottom: endsGroup ? 12 : (hasReaction ? 10 : 4),
      ),
      child: Row(
        mainAxisAlignment: entry.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!entry.isMine) ...[
            SizedBox(width: 28, child: showAvatar ? avatar : null),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Builder(
                  builder: (bubbleContext) {
                    return _BubbleCardContent(
                      entry: entry,
                      endsGroup: endsGroup,
                      onTap: onTap,
                      onLongPress: () {
                        final box = bubbleContext.findRenderObject() as RenderBox?;
                        if (box != null && box.hasSize) {
                          final offset = box.localToGlobal(Offset.zero);
                          final size = box.size;
                          onLongPressWithRect(offset & size);
                        }
                      },
                    );
                  },
                ),
                if (hasReaction)
                  Positioned(
                    bottom: -6,
                    right: entry.isMine ? 10 : null,
                    left: entry.isMine ? null : 10,
                    child: GestureDetector(
                      onTap: onReactionTap,
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bg700, width: 2),
                        ),
                        child: Text(
                          reaction!,
                          style: const TextStyle(fontSize: 13, height: 1.0),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
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
}

class _BubbleCardContent extends StatelessWidget {
  const _BubbleCardContent({
    required this.entry,
    required this.endsGroup,
    this.onTap,
    this.onLongPress,
  });

  final ShareConversationEntry entry;
  final bool endsGroup;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final imageUrl = entry.imageUrl;
    final emoji = entry.outgoingCategory?.iconUrl?.trim();
    return Material(
      color: entry.isMine ? AppColors.primary.withOpacityCompat(.22) : AppColors.d500,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: Radius.circular(!entry.isMine && endsGroup ? 4 : 16),
        bottomRight: Radius.circular(entry.isMine && endsGroup ? 4 : 16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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
                              AppColors.primary.withOpacityCompat(entry.isMine ? .35 : .2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacityCompat(.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        entry.isCategory ? Icons.folder_rounded : Icons.language_rounded,
                        size: 12,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 4),
                      TextWidget(
                        text: entry.isCategory ? '${entry.categoryCount} link' : entry.host,
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
                  decoration: BoxDecoration(gradient: AppGradients.bgDarkGradient),
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationLoading extends StatelessWidget {
  const _ConversationLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
    );
  }
}

class _OlderItemsLoader extends StatelessWidget {
  const _OlderItemsLoader({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              )
            : const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.n500, size: 20),
      ),
    );
  }
}

class _ConversationError extends StatelessWidget {
  const _ConversationError({super.key, required this.message, required this.onRetry});

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
            TextWidget(text: message, color: AppColors.n70, textAlign: TextAlign.center),
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

class _EmptyFilteredResult extends StatelessWidget {
  final ShareConversationController controller;
  const _EmptyFilteredResult({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.92 + (0.08 * value),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacityCompat(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 32,
                  color: AppColors.white.withOpacityCompat(0.4),
                ),
              ),
              const SizedBox(height: 16),
              const TextWidget(
                text: 'Không tìm thấy liên kết phù hợp',
                color: AppColors.white,
                textStyle: AppTextStyle.semiBold16,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: 'Thử tìm kiếm với từ khóa khác hoặc xóa bộ lọc để xem tất cả liên kết.',
                color: AppColors.white.withOpacityCompat(0.55),
                textStyle: AppTextStyle.regular12,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: controller.clearAllFiltersAndSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.navigationSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 16, color: AppColors.white70),
                      SizedBox(width: 6),
                      TextWidget(
                        text: 'Xóa tất cả bộ lọc',
                        color: AppColors.white70,
                        textStyle: AppTextStyle.regular12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showFilterSheet(BuildContext context, ShareConversationController ctrl) {
  Get.bottomSheet(
    _FilterSheet(ctrl: ctrl),
    backgroundColor: AppColors.modalSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  );
}

class _FilterSheet extends StatelessWidget {
  final ShareConversationController ctrl;
  const _FilterSheet({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacityCompat(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              children: [
                const TextWidget(
                  text: 'Bộ lọc liên kết',
                  color: AppColors.white,
                  size: 18,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(width: 8),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacityCompat(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: TextWidget(
                        key: ValueKey('${ctrl.filteredAllItems.length}'),
                        text: '${ctrl.filteredAllItems.length}',
                        color: AppColors.primaryDim,
                        size: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: Get.back,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.white.withOpacityCompat(0.55),
                    size: 21,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sắp xếp
            const TextWidget(
              text: 'Sắp xếp thời gian',
              color: AppColors.white,
              size: 14,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 9),
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: _segmentedOption(
                      label: 'Mới nhất',
                      icon: Icons.arrow_downward_rounded,
                      selected: ctrl.selectedSort.value == ShareSortOption.newest,
                      onTap: () => ctrl.selectSort(ShareSortOption.newest),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _segmentedOption(
                      label: 'Cũ nhất',
                      icon: Icons.arrow_upward_rounded,
                      selected: ctrl.selectedSort.value == ShareSortOption.oldest,
                      onTap: () => ctrl.selectSort(ShareSortOption.oldest),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Người gửi
            const TextWidget(
              text: 'Người gửi',
              color: AppColors.white,
              size: 14,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 9),
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: _segmentedOption(
                      label: 'Tất cả',
                      icon: Icons.people_outline_rounded,
                      selected: ctrl.selectedSender.value == ShareSenderFilter.all,
                      onTap: () => ctrl.selectSender(ShareSenderFilter.all),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _segmentedOption(
                      label: 'Tôi gửi',
                      icon: Icons.upload_rounded,
                      selected: ctrl.selectedSender.value == ShareSenderFilter.mine,
                      onTap: () => ctrl.selectSender(ShareSenderFilter.mine),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _segmentedOption(
                      label: ctrl.friend.displayName.isNotEmpty
                          ? ctrl.friend.displayName
                          : 'Bạn bè',
                      icon: Icons.download_rounded,
                      selected: ctrl.selectedSender.value == ShareSenderFilter.friend,
                      onTap: () => ctrl.selectSender(ShareSenderFilter.friend),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Loại liên kết
            const TextWidget(
              text: 'Loại liên kết',
              color: AppColors.white,
              size: 14,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 9),
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: _segmentedOption(
                      label: 'Tất cả',
                      icon: Icons.all_inclusive_rounded,
                      selected: ctrl.selectedType.value == ShareTypeFilter.all,
                      onTap: () => ctrl.selectType(ShareTypeFilter.all),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _segmentedOption(
                      label: 'Link',
                      icon: Icons.link_rounded,
                      selected: ctrl.selectedType.value == ShareTypeFilter.link,
                      onTap: () => ctrl.selectType(ShareTypeFilter.link),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _segmentedOption(
                      label: 'Danh mục',
                      icon: Icons.folder_open_rounded,
                      selected: ctrl.selectedType.value == ShareTypeFilter.category,
                      onTap: () => ctrl.selectType(ShareTypeFilter.category),
                    ),
                  ),
                ],
              ),
            ),

            // Nguồn liên kết
            Obx(() {
              final sources = ctrl.availableSources;
              if (sources.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  const TextWidget(
                    text: 'Nguồn liên kết',
                    color: AppColors.white,
                    size: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sources.map((s) {
                      final selected = ctrl.selectedSource.value == s.host;
                      return GestureDetector(
                        onTap: () => ctrl.selectSource(selected ? null : s.host),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary.withOpacityCompat(0.2)
                                : AppColors.white.withOpacityCompat(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary.withOpacityCompat(0.6)
                                  : AppColors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LinkSourceUtil.sourceIcon(s.host, size: 14),
                              const SizedBox(width: 6),
                              TextWidget(
                                text: s.label,
                                color: selected
                                    ? AppColors.white
                                    : AppColors.white.withOpacityCompat(0.75),
                                size: 12.5,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.white.withOpacityCompat(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextWidget(
                                  text: '${s.count}',
                                  color: AppColors.white,
                                  size: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            }),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Obx(() {
                    final hasFilters = ctrl.hasActiveFilters;
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: hasFilters ? 1.0 : 0.4,
                      child: GestureDetector(
                        onTap: hasFilters ? ctrl.resetFilters : null,
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacityCompat(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const TextWidget(
                            text: 'Đặt lại',
                            color: AppColors.n80,
                            size: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const TextWidget(
                        text: 'Áp dụng',
                        color: AppColors.white,
                        size: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentedOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacityCompat(0.2)
              : AppColors.white.withOpacityCompat(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary.withOpacityCompat(0.6) : AppColors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? AppColors.primary : AppColors.white.withOpacityCompat(0.55),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: TextWidget(
                text: label,
                color: selected ? AppColors.white : AppColors.white.withOpacityCompat(0.7),
                size: 12.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
