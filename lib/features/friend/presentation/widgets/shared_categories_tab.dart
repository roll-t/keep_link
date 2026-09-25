import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/list_title_widget.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/friend/application/model/shared_category_model.dart';
import 'package:keep_link/features/friend/application/model/shared_individual_link_model.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';
import 'package:keep_link/features/friend/presentation/page/shared_categories_page.dart';
import 'package:keep_link/core/presentation/widgets/shimmer/app_shimmer.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/link_detail_controller.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/page/link_detail.dart';

/// Tab 1: Shared Categories + Individual Links View
class SharedCategoriesTab extends StatelessWidget {
  const SharedCategoriesTab({
    super.key,
    required this.controller,
    required this.onRefresh,
  });

  final SharedCategoryController controller;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.d500,
      onRefresh: onRefresh,
      child: Obx(() {
        final items =
            <Object>[
              ...controller.sharedCategories,
              ...controller.sharedIndividualLinks,
            ]..sort((a, b) {
              final ta =
                  (a is SharedCategoryModel
                      ? a.sharedAt
                      : (a as SharedIndividualLinkModel).sharedAt) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final tb =
                  (b is SharedCategoryModel
                      ? b.sharedAt
                      : (b as SharedIndividualLinkModel).sharedAt) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return tb.compareTo(ta);
            });

        if (controller.isLoading.value && items.isEmpty) {
          return const SharedLoadingView();
        }

        if (controller.errorMessage.value != null && items.isEmpty) {
          return SharedErrorView(
            message: controller.errorMessage.value!,
            onRetry: () => controller.loadAllSharedData(force: true),
          );
        }

        if (items.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: const EmptySharedView(),
              ),
            ),
          );
        }

        return Stack(
          children: [
            ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                indent: 80,
                color: AppColors.white.withOpacityCompat(.06),
              ),
              itemBuilder: (ctx, index) {
                final item = items[index];

                if (item is SharedCategoryModel) {
                  final key = '${item.ownerUid}/${item.categoryId}';
                  return Obx(() {
                    final isUnviewed = controller.unviewedKeys.contains(key);
                    return SharedCategoryCard(
                      category: item,
                      isUnviewed: isUnviewed,
                      onTap: () => openSharedCategoryLinksSheet(
                        context,
                        controller,
                        item,
                      ),
                    );
                  });
                }

                final linkItem = item as SharedIndividualLinkModel;
                final key = '${linkItem.ownerUid}/${linkItem.linkId}';
                return Obx(() {
                  final isUnviewed = controller.unviewedKeys.contains(key);
                  return SharedLinkCard(
                    item: linkItem,
                    isUnviewed: isUnviewed,
                    onTap: () {
                      controller.markLinkViewed(linkItem);
                      Get.toNamed(
                        LinkDetailPage.routeName,
                        arguments: LinkDetailArguments(
                          link: linkItem.link,
                          readOnly: true,
                        ),
                      );
                    },
                  );
                });
              },
            ),
            if (controller.isRefreshing.value)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.primary,
                  backgroundColor: AppColors.transparent,
                ),
              ),
          ],
        );
      }),
    );
  }
}

class SharedCategoryCard extends StatelessWidget {
  const SharedCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.isUnviewed = false,
  });

  final SharedCategoryModel category;
  final VoidCallback onTap;
  final bool isUnviewed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bg700, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ListTitleWidget(
                  title: category.categoryName,
                  subtitle: category.ownerDisplayName,
                  contentPadding: EdgeInsets.zero,
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
                    AppVectors.icShareLink.show(
                      size: 13,
                      color: AppColors.primary,
                    ),
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
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.n500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SharedLinkCard extends StatelessWidget {
  const SharedLinkCard({
    super.key,
    required this.item,
    required this.onTap,
    this.isUnviewed = false,
  });

  final SharedIndividualLinkModel item;
  final VoidCallback onTap;
  final bool isUnviewed;

  @override
  Widget build(BuildContext context) {
    final title = item.link.name ?? item.link.metaDataModel?.title ?? 'Link'.tr;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SharedOwnerAvatar(
                    displayName: item.ownerDisplayName,
                    photoUrl: item.ownerPhotoUrl,
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
                          color: AppColors.danger,
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
                      text: title,
                      color: AppColors.white,
                      size: 15,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_rounded,
                          size: 13,
                          color: AppColors.n70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextWidget(
                            text: item.ownerDisplayName,
                            color: AppColors.n70,
                            size: 13,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacityCompat(0.15),
                  shape: BoxShape.circle,
                ),
                child: AppVectors.icShareLink.show(
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.n500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SharedLoadingView extends StatelessWidget {
  const SharedLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: 4,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 1,
          indent: 80,
          color: AppColors.white.withOpacityCompat(.06),
        ),
        itemBuilder: (_, __) => Container(
          height: 76,
          color: AppColors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 13,
                      width: 130,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 86,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SharedErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const SharedErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

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
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacityCompat(.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_off_rounded,
                      color: AppColors.danger,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextWidget(
                    text: message,
                    color: AppColors.white,
                    size: 15,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Thử lại'),
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

class EmptySharedView extends StatelessWidget {
  const EmptySharedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.d500,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withOpacityCompat(0.08),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.folder_shared_rounded,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: 'no_shared_categories'.tr,
              color: AppColors.white,
              size: 16,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            TextWidget(
              text: 'no_shared_categories_desc'.tr,
              color: AppColors.n70,
              size: 12,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
