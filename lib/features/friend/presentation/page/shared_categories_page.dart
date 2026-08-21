import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:keep_link/core/presentation/widgets/image/cache_image.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/friend/application/model/shared_category_model.dart';
import 'package:keep_link/features/friend/application/model/shared_individual_link_model.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/page/link_detail.dart';

class SharedCategoriesPage extends GetView<SharedCategoryController> {
  static const routeName = '/SharedCategoriesPage';

  const SharedCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.bg700,
        appBar: CustomAppBar(
          title: 'shared_with_me'.tr,
          actions: [
            IconButton(
              onPressed: controller.loadAllSharedData,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.n70),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Column(
          children: [
            // ── Segmented Tab Switcher ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Obx(() {
                final catCount = controller.sharedCategories.length;
                final linkCount = controller.sharedIndividualLinks.length;
                final tab = controller.selectedTab.value;

                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.d500,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      // Tab 1: Danh mục
                      Expanded(
                        child: _SegmentTab(
                          icon: Icons.folder_shared_rounded,
                          title: '${'shared_categories'.tr} ($catCount)',
                          isSelected: tab == 0,
                          onTap: () => controller.selectedTab.value = 0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Tab 2: Liên kết lẻ
                      Expanded(
                        child: _SegmentTab(
                          icon: Icons.link_rounded,
                          title: '${'shared_links'.tr} ($linkCount)',
                          isSelected: tab == 1,
                          onTap: () => controller.selectedTab.value = 1,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            // ── Tab Content ─────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (controller.selectedTab.value == 0) {
                  return _CategoriesTab(controller: controller);
                } else {
                  return _IndividualLinksTab(controller: controller);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segment Tab Button ───────────────────────────────────────────────────────

class _SegmentTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.n70,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: TextWidget(
                  text: title,
                  color: isSelected ? Colors.white : AppColors.n70,
                  size: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab 1: Categories ────────────────────────────────────────────────────────

class _CategoriesTab extends StatelessWidget {
  final SharedCategoryController controller;

  const _CategoriesTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.sharedCategories.isEmpty) {
      return _EmptyShared(
        icon: Icons.folder_shared_rounded,
        title: 'no_shared_categories'.tr,
        desc: 'no_shared_categories_desc'.tr,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 32),
      physics: const BouncingScrollPhysics(),
      itemCount: controller.sharedCategories.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.white.withOpacityCompat(0.06),
        indent: 74,
      ),
      itemBuilder: (ctx, index) {
        final cat = controller.sharedCategories[index];
        final key = '${cat.ownerUid}/${cat.categoryId}';
        return Obx(() {
          final isUnviewed = controller.unviewedKeys.contains(key);
          return _SharedCategoryCard(
            category: cat,
            isUnviewed: isUnviewed,
            onTap: () => openSharedCategoryLinksSheet(ctx, controller, cat),
          );
        });
      },
    );
  }
}

// ── Tab 2: Individual Links ──────────────────────────────────────────────────

class _IndividualLinksTab extends StatelessWidget {
  final SharedCategoryController controller;

  const _IndividualLinksTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.sharedIndividualLinks.isEmpty) {
      return _EmptyShared(
        icon: Icons.link_off_rounded,
        title: 'no_shared_links'.tr,
        desc: 'no_shared_links_desc'.tr,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      physics: const BouncingScrollPhysics(),
      itemCount: controller.sharedIndividualLinks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final item = controller.sharedIndividualLinks[index];
        final key = '${item.ownerUid}/${item.linkId}';
        return Obx(() {
          final isUnviewed = controller.unviewedKeys.contains(key);
          return _SharedIndividualLinkCard(
            item: item,
            isUnviewed: isUnviewed,
            onTap: () {
              controller.markLinkViewed(item);
              Get.toNamed(LinkDetailPage.routeName, arguments: item.link);
            },
            onSave: () => controller.saveSharedLinkToMyCollection(item),
          );
        });
      },
    );
  }
}

// ── Individual Link Card ─────────────────────────────────────────────────────

class _SharedIndividualLinkCard extends StatelessWidget {
  final SharedIndividualLinkModel item;
  final bool isUnviewed;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const _SharedIndividualLinkCard({
    required this.item,
    this.isUnviewed = false,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final meta = item.link.metaDataModel;
    final title = item.link.name ?? meta?.title ?? 'Link';
    final description = meta?.description ?? '';
    final imageUrl = meta?.imageUrl ?? '';
    final url = meta?.url;
    final host = url != null ? Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? '' : '';

    return Material(
      color: AppColors.d500,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnviewed
                  ? AppColors.primary.withOpacityCompat(0.4)
                  : AppColors.white.withOpacityCompat(0.06),
              width: isUnviewed ? 1.2 : 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sender Info Header
              Row(
                children: [
                  SharedOwnerAvatar(
                    displayName: item.ownerDisplayName,
                    photoUrl: item.ownerPhotoUrl,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: AppColors.n70),
                        children: [
                          TextSpan(text: '${'shared_by'.tr} '),
                          TextSpan(
                            text: item.ownerDisplayName,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isUnviewed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextWidget(
                        text: 'NEW',
                        color: Colors.white,
                        size: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // 2. Link Thumbnail & Content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CacheImageWidget(
                      imageUrl: imageUrl,
                      width: 100,
                      height: 64,
                      fit: BoxFit.cover,
                      emptyIcon: Icons.photo_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title & Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: title,
                          color: AppColors.white,
                          size: 14,
                          fontWeight: FontWeight.w600,
                          maxLines: 2,
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          TextWidget(
                            text: description,
                            color: AppColors.n70,
                            size: 11.5,
                            maxLines: 1,
                          ),
                        ],
                        if (host.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.public_rounded, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextWidget(
                                  text: host,
                                  color: AppColors.primary,
                                  size: 11,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 3. Action Row: Save to My Collection
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: onSave,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacityCompat(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacityCompat(0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bookmark_add_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          TextWidget(
                            text: 'save_to_collection'.tr,
                            color: AppColors.primary,
                            size: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyShared extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _EmptyShared({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.n500.withOpacityCompat(0.6),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: title,
              color: AppColors.n70,
              size: 16,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: desc,
              color: AppColors.n500,
              size: 13,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Card ─────────────────────────────────────────────────────────────

class _SharedCategoryCard extends StatelessWidget {
  const _SharedCategoryCard({required this.category, required this.onTap, this.isUnviewed = false});

  final SharedCategoryModel category;
  final VoidCallback onTap;
  final bool isUnviewed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SharedOwnerAvatar(
                    displayName: category.ownerDisplayName,
                    photoUrl: category.ownerPhotoUrl,
                    size: 46,
                  ),
                  if (isUnviewed)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bg700, width: 2),
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
                    TextWidget(
                      text: category.categoryName,
                      color: AppColors.white,
                      size: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 13, color: AppColors.n70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextWidget(
                            text: category.ownerDisplayName,
                            color: AppColors.n70,
                            size: 13,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    if (category.categoryDescription != null &&
                        category.categoryDescription!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      TextWidget(
                        text: category.categoryDescription!,
                        color: AppColors.n500,
                        size: 12,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacityCompat(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    TextWidget(
                      text: '${category.linkCount}',
                      color: AppColors.primary,
                      size: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.n500, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared Owner Avatar ───────────────────────────────────────────────────────

class SharedOwnerAvatar extends StatelessWidget {
  const SharedOwnerAvatar({super.key, required this.displayName, this.photoUrl, this.size = 40});

  final String displayName;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CacheImageWidget(
        imageUrl: photoUrl!,
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(size / 2),
      );
    }

    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacityCompat(0.2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: TextWidget(
        text: initial,
        color: AppColors.primary,
        size: size * 0.42,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── Links Sheet (Bottom Sheet for Shared Category) ────────────────────────────

void openSharedCategoryLinksSheet(
  BuildContext context,
  SharedCategoryController controller,
  SharedCategoryModel category,
) {
  controller.markCategoryViewed(category);
  controller.openSharedCategory(category);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.d500,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.8,
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.n500.withOpacityCompat(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    SharedOwnerAvatar(
                      displayName: category.ownerDisplayName,
                      photoUrl: category.ownerPhotoUrl,
                      size: 38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: category.categoryName,
                            color: AppColors.white,
                            size: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          TextWidget(
                            text: '${'shared_by'.tr} ${category.ownerDisplayName}',
                            color: AppColors.n70,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: AppColors.n500.withOpacityCompat(0.2), height: 1),
              // Links list
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingLinks.value) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  if (controller.sharedLinks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: TextWidget(
                          text: 'no_links_in_category'.tr,
                          color: AppColors.n70,
                          size: 14,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller.sharedLinks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final link = controller.sharedLinks[i];
                      return _SharedLinkItem(
                        link: link,
                        onTap: () {
                          Get.toNamed(LinkDetailPage.routeName, arguments: link);
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(controller.closeSharedCategory);
}

// ── Shared Link Item inside Category Sheet ───────────────────────────────────

class _SharedLinkItem extends StatelessWidget {
  final LinkModel link;
  final VoidCallback onTap;

  const _SharedLinkItem({required this.link, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = link.metaDataModel;
    final title = link.name ?? meta?.title ?? 'Link';
    final imageUrl = meta?.imageUrl ?? '';
    final url = meta?.url;
    final host = url != null ? Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? '' : '';

    return Material(
      color: AppColors.bg700,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 76),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail tràn sát mép card hoàn toàn, không khoảng cách xung quanh
                SizedBox(
                  width: 80,
                  child: CacheImageWidget(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    emptyIcon: Icons.photo_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextWidget(
                          text: title,
                          color: AppColors.white,
                          size: 13.5,
                          fontWeight: FontWeight.w600,
                          maxLines: 2,
                        ),
                        if (host.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          TextWidget(
                            text: host,
                            color: AppColors.n70,
                            size: 11,
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.n500, size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
