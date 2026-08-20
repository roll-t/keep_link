import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:keep_link/core/presentation/widgets/image/cache_image.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/friend/application/model/shared_category_model.dart';
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
              onPressed: controller.loadSharedCategories,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.n70),
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (controller.sharedCategories.isEmpty) {
            return _EmptyShared();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: controller.sharedCategories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final cat = controller.sharedCategories[index];
              final key = '${cat.ownerUid}/${cat.categoryId}';
              return Obx(() {
                final isUnviewed = controller.unviewedKeys.contains(key);
                return _SharedCategoryCard(
                  category: cat,
                  isUnviewed: isUnviewed,
                  onTap: () => openSharedCategoryLinksSheet(context, controller, cat),
                );
              });
            },
          );
        }),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyShared extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_shared_rounded,
              size: 64,
              color: AppColors.n500.withOpacityCompat(0.6),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: 'no_shared_categories'.tr,
              color: AppColors.n70,
              size: 16,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: 'no_shared_categories_desc'.tr,
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
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.d500,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.n500.withOpacityCompat(0.18)),
            ),
            child: Row(
              children: [
                // Owner avatar
                SharedOwnerAvatar(
                  displayName: category.ownerDisplayName,
                  photoUrl: category.ownerPhotoUrl,
                ),
                const SizedBox(width: 14),
                // Category info
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_rounded, size: 13, color: AppColors.n70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextWidget(
                              text: category.ownerDisplayName,
                              color: AppColors.n70,
                              size: 12,
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
                const SizedBox(width: 12),
                // Link count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacityCompat(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link_rounded, size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      TextWidget(
                        text: '${category.linkCount}',
                        color: AppColors.primary,
                        size: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.n500.withOpacityCompat(0.6),
                ),
              ],
            ),
          ),
          if (isUnviewed)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens the bottom sheet listing the links inside [category].
/// Shared between [SharedCategoriesPage] and the "shared with you" preview
/// section on the Friends page so both use identical behaviour.
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
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _SharedLinksSheet(controller: controller, category: category),
  ).whenComplete(controller.closeSharedCategory);
}

class SharedOwnerAvatar extends StatelessWidget {
  const SharedOwnerAvatar({super.key, required this.displayName, this.photoUrl, this.size = 44});

  final String displayName;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl ?? '';
    if (url.isNotEmpty) {
      return CacheImageWidget(
        imageUrl: url,
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(size / 2),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacityCompat(0.2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: TextWidget(
        text: displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        color: AppColors.primary,
        size: size * 0.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── Links Sheet ───────────────────────────────────────────────────────────────

class _SharedLinksSheet extends StatelessWidget {
  const _SharedLinksSheet({required this.controller, required this.category});

  final SharedCategoryController controller;
  final SharedCategoryModel category;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.75,
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                SharedOwnerAvatar(
                  displayName: category.ownerDisplayName,
                  photoUrl: category.ownerPhotoUrl,
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
                        text: 'shared_by'.trArgs([category.ownerDisplayName]),
                        color: AppColors.n70,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.n500.withOpacityCompat(0.2), height: 1),
          // Links list
          Expanded(
            child: Obx(() {
              if (controller.isLoadingLinks.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (controller.sharedLinks.isEmpty) {
                return Center(
                  child: TextWidget(
                    text: 'no_links_in_shared_category'.tr,
                    color: AppColors.n70,
                    size: 14,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: controller.sharedLinks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _SharedLinkItem(link: controller.sharedLinks[index]),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SharedLinkItem extends StatelessWidget {
  const _SharedLinkItem({required this.link});

  final LinkModel link;

  Future<void> _launch() async {
    Get.bottomSheet(
      LinkDetailPage(link: link),
      barrierColor: AppColors.black.withOpacityCompat(.8),
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = link.metaDataModel?.imageUrl ?? '';
    final title = link.name ?? link.metaDataModel?.title ?? link.metaDataModel?.url ?? '';

    return GestureDetector(
      onTap: _launch,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg700,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.n500.withOpacityCompat(0.15)),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? CacheImageWidget(imageUrl: imageUrl, width: 48, height: 48)
                  : Container(
                      width: 48,
                      height: 48,
                      color: AppColors.d300,
                      child: const Icon(Icons.link_rounded, color: AppColors.n70, size: 24),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    TextWidget(
                      text: title,
                      color: AppColors.white,
                      size: 13,
                      fontWeight: FontWeight.w600,
                      maxLines: 2,
                    ),
                  if (link.metaDataModel?.url != null) ...[
                    const SizedBox(height: 2),
                    TextWidget(
                      text: link.metaDataModel!.url,
                      color: AppColors.primary,
                      size: 11,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.n500.withOpacityCompat(0.6),
            ),
          ],
        ),
      ),
    );
  }
}
