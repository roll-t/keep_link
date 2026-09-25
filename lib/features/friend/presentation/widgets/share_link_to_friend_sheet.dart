import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_edge_insets.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/repositories/category_repository.dart';
import 'package:keep_link/core/data/repositories/link_repository.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/shimmer/app_shimmer.dart';
import 'package:keep_link/core/presentation/widgets/tab/app_segmented_tab.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/presentation/widgets/text_field/search_input_field.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/presentation/page/shared_categories_page.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/widgets/link_item.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/link_detail_controller.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/page/link_detail.dart';

void openShareLinkToFriendSheet(BuildContext context, FriendModel friend) {
  showModalBottomSheet<void>(
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
  String? _sharingId;
  final Set<String> _sharedLinkIds = <String>{};
  final Set<String> _sharedCategoryIds = <String>{};

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
      await Future.wait([LinkRepository.ensureLoaded(), CategoryRepository.ensureLoaded()]);
      final results = await Future.wait([
        FirebaseService.getLinkIdsSharedWithFriend(widget.friend.friendUserId),
        FirebaseService.getCategoryIdsSharedWithFriend(widget.friend.friendUserId),
      ]);
      _sharedLinkIds
        ..clear()
        ..addAll(results[0]);
      _sharedCategoryIds
        ..clear()
        ..addAll(results[1]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLinkShare(LinkModel link) async {
    if (_sharingId != null) return;
    setState(() => _sharingId = link.id);
    final wasShared = _sharedLinkIds.contains(link.id);
    try {
      if (wasShared) {
        await FirebaseService.unshareLink(friendUid: widget.friend.friendUserId, linkId: link.id);
        _sharedLinkIds.remove(link.id);
        AppToast.showToast(
          'unshare_link_success'.tr,
          Icons.link_off_rounded,
          color: AppColors.warning,
        );
      } else {
        await FirebaseService.shareLink(friendUid: widget.friend.friendUserId, linkId: link.id);
        _sharedLinkIds.add(link.id);
        AppToast.showToast(
          'share_link_success'.tr,
          Icons.check_circle_rounded,
          color: AppColors.success,
        );
      }
      if (mounted) setState(() {});
    } catch (_) {
      AppToast.showToast(
        'share_link_failed'.tr,
        Icons.error_outline_rounded,
        color: AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _sharingId = null);
    }
  }

  Future<void> _toggleCategoryShare(CategoryModel category) async {
    final catId = category.id;
    if (catId == null || _sharingId != null) return;
    setState(() => _sharingId = catId);
    final wasShared = _sharedCategoryIds.contains(catId);
    try {
      if (wasShared) {
        await FirebaseService.unshareCategory(
          friendUid: widget.friend.friendUserId,
          categoryId: catId,
        );
        _sharedCategoryIds.remove(catId);
        AppCache.removeSharedFriend(catId, widget.friend.friendUserId);
        AppToast.showToast(
          '${'category_unshared'.tr}: ${category.name ?? ''}',
          Icons.link_off_rounded,
          color: AppColors.warning,
        );
      } else {
        await FirebaseService.shareCategory(
          friendUid: widget.friend.friendUserId,
          categoryId: catId,
        );
        _sharedCategoryIds.add(catId);
        AppCache.addSharedFriend(catId, widget.friend);
        AppToast.showToast(
          '${'category_shared'.tr}: ${category.name ?? ''}',
          Icons.check_circle_rounded,
          color: AppColors.success,
        );
      }
      if (mounted) setState(() {});
    } catch (_) {
      AppToast.showToast(
        'share_update_failed'.tr,
        Icons.error_outline_rounded,
        color: AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _sharingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final allLinks = AppCache.links;
    final allCategories = AppCache.categories.where((c) => c.id != null && c.id != 'all').toList();
    final q = _query.trim().toLowerCase();

    final filteredLinks = q.isEmpty
        ? allLinks
        : allLinks.where((l) {
            final title = (l.name ?? l.metaDataModel?.title ?? '').toLowerCase();
            final url = (l.metaDataModel?.url ?? '').toLowerCase();
            return title.contains(q) || url.contains(q);
          }).toList();

    return AnimatedPadding(
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
                              text: _selectedTab == 0 ? 'share_link'.tr : 'share_category'.tr,
                              color: AppColors.white,
                              size: 16,
                              fontWeight: FontWeight.w700,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            TextWidget(
                              text: '${'share_send_to'.tr} ${widget.friend.displayName}',
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
                          color: _selectedTab == 0 ? AppColors.white : AppColors.n70,
                        ),
                        count: allLinks.length,
                      ),
                      AppSegmentTabItem(
                        label: 'Categories'.tr,
                        icon: AppVectors.icCategory.show(
                          size: 15,
                          color: _selectedTab == 1 ? AppColors.white : AppColors.n70,
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
                      ? (_selectedTab == 0
                            ? const LinkListShimmer(thumbnailWidth: 120, hasTrailingButton: true)
                            : const CategoryListShimmer(hasTrailingButton: true))
                      : _selectedTab == 0
                      ? _buildLinksList(filteredLinks, q)
                      : _buildCategoriesList(allCategories),
                ),
              ],
            ),
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
              const Icon(Icons.link_off_rounded, size: 44, color: AppColors.n500),
              const SizedBox(height: 10),
              TextWidget(
                text: q.isEmpty ? 'No links available to share'.tr : 'No matching links'.tr,
                color: AppColors.n70,
                textStyle: AppTextStyle.regular14,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => Divider(
        height: .5,
        thickness: 0.8,
        indent: 0,
        endIndent: 0,
        color: AppColors.white.withOpacityCompat(0.10),
      ),
      itemBuilder: (context, index) {
        final link = filtered[index];
        final isSending = _sharingId == link.id;
        final isAlreadyShared = _sharedLinkIds.contains(link.id);
        return LinkListItem(
          index: index,
          item: link,
          thumbnailWidth: 120,
          onTap: () {
            Get.toNamed(LinkDetailPage.routeName, arguments: LinkDetailArguments(link: link));
          },
          trailing: isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : ShareStatusButton(isShared: isAlreadyShared, onTap: () => _toggleLinkShare(link)),
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
              const Icon(Icons.folder_off_rounded, size: 44, color: AppColors.n500),
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

    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: categories.length,
      separatorBuilder: (_, __) => Divider(
        height: .5,
        thickness: 0.8,
        indent: 0,
        endIndent: 0,
        color: AppColors.white.withOpacityCompat(0.10),
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSending = _sharingId == category.id;
        final count =
            category.chilrenCount ??
            AppCache.links.where((l) => l.categoryId == category.id).length;
        final isAlreadyShared = _sharedCategoryIds.contains(category.id);

        return Material(
          color: AppColors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacityCompat(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: AppVectors.icCategory.show(size: 22, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: category.name ?? 'Category',
                        color: AppColors.white,
                        textStyle: AppTextStyle.semiBold14,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      TextWidget(
                        text: (category.description?.isNotEmpty ?? false)
                            ? '$count ${'links'.tr} • ${category.description}'
                            : '$count ${'links'.tr}',
                        color: AppColors.white.withOpacityCompat(0.4),
                        textStyle: AppTextStyle.regular12,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (isSending)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                else
                  ShareStatusButton(
                    isShared: isAlreadyShared,
                    onTap: () => _toggleCategoryShare(category),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShareStatusButton extends StatelessWidget {
  const ShareStatusButton({super.key, required this.isShared, required this.onTap});

  final bool isShared;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isShared ? AppColors.warning : AppColors.primary;
    return Material(
      color: color.withOpacityCompat(0.14),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isShared ? Icons.link_off_rounded : Icons.ios_share_rounded,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 4),
              TextWidget(
                text: isShared ? 'revoke_share'.tr : 'share_action'.tr,
                color: color,
                textStyle: AppTextStyle.medium10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
