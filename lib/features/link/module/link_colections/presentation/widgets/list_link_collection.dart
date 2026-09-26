import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/widgets/shimmer/app_shimmer.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/link_collection_controller.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/widgets/link_item.dart';

class ListLinkCollection extends GetView<LinkCollectionController> {
  const ListLinkCollection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.listLink.isEmpty) {
        final topInset = MediaQuery.paddingOf(context).top + 81;
        return LinkGridShimmer(padding: EdgeInsets.fromLTRB(12, topInset, 12, 112));
      }

      final listLink = controller.listLink;
      if (listLink.isEmpty) {
        return _buildEmptyState();
      }

      return _buildLinkGrid(context, listLink, isLoadingMore: controller.isLoadMore.value);
    });
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: controller.onRefreshData,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppVectors.icEmpty.show(color: AppColors.navigationSurface, size: Get.width * .3),
                  const SizedBox(height: 18),
                  const TextWidget(
                    text: "No links yet",
                    color: AppColors.white,
                    textStyle: AppTextStyle.medium18,
                  ),
                  const SizedBox(height: 6),
                  const TextWidget(
                    text: "Save your favorite links",
                    color: AppColors.primaryContainer,
                    textStyle: AppTextStyle.regular12,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: controller.onRefreshData,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.navigationSurface,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            const Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: AppColors.primaryContainer,
                            ),
                            Center(
                              child: TextWidget(
                                text: 'Reload'.tr,
                                color: AppColors.primaryContainer,
                                textStyle: AppTextStyle.regular14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkGrid(
    BuildContext context,
    List<LinkModel> listLink, {
    required bool isLoadingMore,
  }) {
    final topInset = MediaQuery.paddingOf(context).top + 81;
    return RefreshIndicator(
      onRefresh: controller.onRefreshData,
      child: Stack(
        children: [
          GridView.builder(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 112, left: 8, right: 8).copyWith(top: topInset),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: .85,
            ),
            itemCount: listLink.length + (isLoadingMore ? 2 : 0),
            itemBuilder: (context, index) {
              if (index >= listLink.length) {
                return const AppShimmer(child: LinkGridItemSkeleton());
              }
              final item = listLink[index];
              return LinkItem(
                key: ValueKey(item.id),
                index: index,
                item: item,
                controller: controller,
              );
            },
          ),
          Obx(() {
            if (!controller.isRefreshing.value) {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: topInset - 1,
              left: 0,
              right: 0,
              child: const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.primary,
                backgroundColor: AppColors.transparent,
              ),
            );
          }),
        ],
      ),
    );
  }
}
