import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_icons.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_edge_insets.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/repositories/category_repository.dart';
import 'package:keep_link/core/data/repositories/link_repository.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/image/cache_image.dart';
import 'package:keep_link/core/presentation/widgets/shimmer/app_shimmer.dart';
import 'package:keep_link/core/presentation/widgets/tab/app_segmented_tab.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/presentation/widgets/text_field/search_input_field.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';
import 'package:keep_link/features/friend/presentation/page/shared_categories_page.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

Future<bool?> openShareLinkToFriendSheet(
  BuildContext context,
  FriendModel friend,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ShareLinkToFriendSheet(friend: friend),
  );
}

class ShareLinkToFriendSheet extends StatefulWidget {
  const ShareLinkToFriendSheet({super.key, required this.friend});

  final FriendModel friend;

  @override
  State<ShareLinkToFriendSheet> createState() => _ShareLinkToFriendSheetState();
}

class _ShareLinkToFriendSheetState extends State<ShareLinkToFriendSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedTab = 0; // 0: Link, 1: Category
  String _query = '';
  bool _isLoading = true;
  bool _isSharing = false;
  bool _hasChanged = false;
  bool _isClosing = false;
  final Set<String> _selectedLinkIds = <String>{};
  final Set<String> _selectedCategoryIds = <String>{};

  int get _selectedCount =>
      _selectedLinkIds.length + _selectedCategoryIds.length;

  void _closeSheet([bool? result]) {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    Navigator.of(context).pop(result ?? _hasChanged);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await Future.wait([
        LinkRepository.ensureLoaded(),
        CategoryRepository.ensureLoaded(),
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleLinkSelection(LinkModel link) {
    if (_isSharing) return;
    setState(() {
      if (!_selectedLinkIds.add(link.id)) {
        _selectedLinkIds.remove(link.id);
      }
    });
  }

  void _toggleCategorySelection(CategoryModel category) {
    final catId = category.id;
    if (catId == null || _isSharing) {
      return;
    }
    setState(() {
      if (!_selectedCategoryIds.add(catId)) {
        _selectedCategoryIds.remove(catId);
      }
    });
  }

  Future<void> _sendSelected() async {
    if (_isSharing || _selectedCount == 0) return;
    setState(() => _isSharing = true);

    final selectedLinks = Set<String>.from(_selectedLinkIds);
    final selectedCategories = Set<String>.from(_selectedCategoryIds);
    final selectedCount = selectedLinks.length + selectedCategories.length;

    try {
      await FirebaseService.shareItemsBatch(
        friendUid: widget.friend.friendUserId,
        linkIds: selectedLinks,
        categoryIds: selectedCategories,
      );
      for (final categoryId in selectedCategories) {
        final category = AppCache.categories.firstWhereOrNull(
          (item) => item.id == categoryId,
        );
        if (category != null) {
          AppCache.addSharedFriend(categoryId, widget.friend);
        }
      }
      _hasChanged = true;
      if (Get.isRegistered<SharedCategoryController>()) {
        Get.find<SharedCategoryController>().notifyOutgoingSharesChanged();
      }
      AppToast.success(
        'share_items_sent'.trParams({'count': '$selectedCount'}),
      );

      if (!mounted) return;
      _closeSheet(true);
    } catch (_) {
      AppToast.error('share_update_failed'.tr);
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final allLinks = AppCache.links;
    final allCategories = AppCache.categories
        .where((c) => c.id != null && c.id != 'all')
        .toList();
    final q = _query.trim().toLowerCase();

    final filteredLinks = q.isEmpty
        ? allLinks
        : allLinks.where((l) {
            final title = (l.name ?? l.metaDataModel?.title ?? '')
                .toLowerCase();
            final url = (l.metaDataModel?.url ?? '').toLowerCase();
            return title.contains(q) || url.contains(q);
          }).toList();

    return PopScope(
      canPop: _isClosing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isClosing) {
          _closeSheet(_hasChanged);
        }
      },
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: media.size.height * 0.9,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.n70.withOpacityCompat(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        SharedOwnerAvatar(
                          displayName: widget.friend.displayName,
                          photoUrl: widget.friend.photoUrl,
                          size: 38,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: _selectedTab == 0
                                    ? 'share_link'.tr
                                    : 'share_category'.tr,
                                color: AppColors.white,
                                size: 16,
                                fontWeight: FontWeight.w700,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              TextWidget(
                                text:
                                    '${'share_send_to'.tr} ${widget.friend.displayName}',
                                color: AppColors.n70,
                                size: 12,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: AppEdgeInsets.h16,
                    child: AppSegmentedTab(
                      selectedIndex: _selectedTab,
                      onChanged: (index) {
                        setState(() {
                          _selectedTab = index;
                          if (index == 1) {
                            _query = '';
                            _searchCtrl.clear();
                          }
                        });
                      },
                      tabs: [
                        AppSegmentTabItem(
                          label: 'Links'.tr,
                          icon: AppVectors.icShareLink.show(
                            size: 15,
                            color: _selectedTab == 0
                                ? AppColors.white
                                : AppColors.n70,
                          ),
                          count: allLinks.length,
                        ),
                        AppSegmentTabItem(
                          label: 'Categories'.tr,
                          icon: AppVectors.icCategory.show(
                            size: 15,
                            color: _selectedTab == 1
                                ? AppColors.white
                                : AppColors.n70,
                          ),
                          count: allCategories.length,
                        ),
                      ],
                    ),
                  ),
                  if (_selectedTab == 0) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: AppEdgeInsets.h16,
                      child: SearchInputField(
                        controller: _searchCtrl,
                        hintText: 'Search links'.tr,
                        height: 38,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoading
                        ? _buildGridLoading()
                        : _selectedTab == 0
                        ? _buildLinksList(filteredLinks, q)
                        : _buildCategoriesList(allCategories),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _selectedCount == 0
                        ? const SizedBox.shrink(key: ValueKey('no-send-button'))
                        : _buildSendButton(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridLoading() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: .85,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const AppShimmer(child: LinkGridItemSkeleton()),
    );
  }

  Widget _buildSendButton() {
    return Container(
      key: const ValueKey('send-button'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.white.withOpacityCompat(.08)),
        ),
      ),
      child: SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _isSharing ? null : _sendSelected,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withOpacityCompat(.5),
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: _isSharing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 19),
          label: TextWidget(
            text: '${'share_send'.tr} ($_selectedCount)',
            color: AppColors.white,
            textStyle: AppTextStyle.semiBold14,
          ),
        ),
      ),
    );
  }

  Widget _buildLinksList(List<LinkModel> filtered, String q) {
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.link_off_rounded,
                size: 44,
                color: AppColors.n500,
              ),
              const SizedBox(height: 10),
              TextWidget(
                text: q.isEmpty
                    ? 'No links available to share'.tr
                    : 'No matching links'.tr,
                color: AppColors.n70,
                textStyle: AppTextStyle.regular14,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: .85,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final link = filtered[index];
        return _SelectableLinkGridItem(
          key: ValueKey(link.id),
          link: link,
          selected: _selectedLinkIds.contains(link.id),
          alreadyShared: false,
          onTap: () => _toggleLinkSelection(link),
        );
      },
    );
  }

  Widget _buildCategoriesList(List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.folder_off_rounded,
                size: 44,
                color: AppColors.n500,
              ),
              const SizedBox(height: 10),
              TextWidget(
                text: 'No categories available to share'.tr,
                color: AppColors.n70,
                textStyle: AppTextStyle.regular14,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: .85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final count =
            category.chilrenCount ??
            AppCache.links.where((l) => l.categoryId == category.id).length;
        final categoryId = category.id;
        return _SelectableCategoryGridItem(
          key: ValueKey(categoryId),
          category: category,
          linkCount: count,
          selected:
              categoryId != null && _selectedCategoryIds.contains(categoryId),
          alreadyShared: false,
          onTap: () => _toggleCategorySelection(category),
        );
      },
    );
  }
}

class _SelectableLinkGridItem extends StatelessWidget {
  const _SelectableLinkGridItem({
    super.key,
    required this.link,
    required this.selected,
    required this.alreadyShared,
    required this.onTap,
  });

  final LinkModel link;
  final bool selected;
  final bool alreadyShared;
  final VoidCallback onTap;

  String get _host {
    final url = link.metaDataModel?.url ?? '';
    return Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? '';
  }

  Widget? _appIcon(String host) {
    if (host.contains('tiktok.com')) {
      return AppIcons.icLogoTiktok.show(size: 12);
    }
    if (host.contains('twitter.com') || host.contains('x.com')) {
      return AppIcons.icLogoTwitter.show(size: 12);
    }
    if (host.contains('instagram.com')) {
      return AppIcons.icLogoInstagram.show(size: 12);
    }
    if (host.contains('facebook.com') || host.contains('fb.com')) {
      return AppIcons.icLogoFacebook.show(size: 12);
    }
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return AppIcons.icLogoYoutube.show(size: 12);
    }
    if (host.contains('google.com')) {
      return AppIcons.icLogoGoogle.show(size: 12);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final meta = link.metaDataModel;
    final host = _host;
    final icon = _appIcon(host);
    final title = (link.name?.trim().isNotEmpty ?? false)
        ? link.name!
        : (meta?.title ?? meta?.url ?? 'Link');

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: alreadyShared ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: AppColors.navigationSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.white.withOpacityCompat(.06),
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: CacheImageWidget(
                  imageUrl: link.displayImage,
                  fit: BoxFit.cover,
                  memCacheWidth: 480,
                  memCacheHeight: 480,
                  borderRadius: BorderRadius.circular(8),
                  emptyIcon: Icons.link_rounded,
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                right: 42,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _GridItemChip(
                    label: alreadyShared ? 'share_already_sent'.tr : host,
                    icon: alreadyShared
                        ? const Icon(
                            Icons.done_all_rounded,
                            size: 12,
                            color: AppColors.white,
                          )
                        : icon,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.fromLTRB(9, 18, 9, 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                    gradient: AppGradients.bgDarkGradient,
                  ),
                  alignment: Alignment.bottomLeft,
                  child: TextWidget(
                    text: title,
                    color: AppColors.white,
                    textStyle: AppTextStyle.semiBold14,
                    maxLines: 2,
                  ),
                ),
              ),
              if (selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: AppColors.primary.withOpacityCompat(.12),
                    ),
                  ),
                ),
              if (alreadyShared)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: AppColors.black.withOpacityCompat(.32),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: _SelectionCircle(
                  selected: selected,
                  alreadyShared: alreadyShared,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableCategoryGridItem extends StatelessWidget {
  const _SelectableCategoryGridItem({
    super.key,
    required this.category,
    required this.linkCount,
    required this.selected,
    required this.alreadyShared,
    required this.onTap,
  });

  final CategoryModel category;
  final int linkCount;
  final bool selected;
  final bool alreadyShared;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final emoji = category.iconUrl?.trim();
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: alreadyShared ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.white.withOpacityCompat(.06),
              width: selected ? 2 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacityCompat(.28),
                AppColors.navigationSurface,
                AppColors.d500,
              ],
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Center(
                child: emoji != null && emoji.isNotEmpty
                    ? TextWidget(text: emoji, size: 46)
                    : AppVectors.icCategory.show(
                        size: 52,
                        color: AppColors.primaryBright,
                      ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: _GridItemChip(
                  label: alreadyShared
                      ? 'share_already_sent'.tr
                      : '$linkCount ${'links'.tr}',
                  icon: Icon(
                    alreadyShared ? Icons.done_all_rounded : Icons.link_rounded,
                    size: 12,
                    color: AppColors.white,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.fromLTRB(9, 16, 9, 9),
                  decoration: BoxDecoration(
                    gradient: AppGradients.bgDarkGradient,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: category.name ?? 'Category',
                        color: AppColors.white,
                        textStyle: AppTextStyle.semiBold14,
                        maxLines: 1,
                      ),
                      if (category.description?.isNotEmpty ?? false)
                        TextWidget(
                          text: category.description!,
                          color: AppColors.n70,
                          textStyle: AppTextStyle.regular10,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
              ),
              if (selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: AppColors.primary.withOpacityCompat(.12),
                    ),
                  ),
                ),
              if (alreadyShared)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: AppColors.black.withOpacityCompat(.32),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: _SelectionCircle(
                  selected: selected,
                  alreadyShared: alreadyShared,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridItemChip extends StatelessWidget {
  const _GridItemChip({required this.label, this.icon});

  final String label;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacityCompat(.58),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 4)],
          Flexible(
            child: TextWidget(
              text: label,
              color: AppColors.white,
              size: 10,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({required this.selected, required this.alreadyShared});

  final bool selected;
  final bool alreadyShared;

  @override
  Widget build(BuildContext context) {
    final active = selected || alreadyShared;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? AppColors.primary
            : alreadyShared
            ? AppColors.n500
            : AppColors.black.withOpacityCompat(.48),
        border: Border.all(color: AppColors.white, width: 1),
      ),
      child: active
          ? Icon(
              alreadyShared ? Icons.done_all_rounded : Icons.check_rounded,
              size: 10,
              color: AppColors.white,
            )
          : null,
    );
  }
}
