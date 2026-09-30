import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/link_collection_controller.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/share_link_sheet.dart';

class SelectionActionBar extends GetView<LinkCollectionController> {
  const SelectionActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final sidePadding = MediaQuery.sizeOf(context).width * 0.04;

    return Obx(() {
      final count = controller.selectedIds.length;
      final isAll = controller.isAllSelected;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: sidePadding),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.navigationSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Cancel button
                TextButton(
                  onPressed: controller.exitSelectionMode,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: TextWidget(
                    text: 'Huỷ',
                    color: AppColors.white,
                    textStyle: AppTextStyle.semiBold14,
                  ),
                ),

                // Selected count (center)
                Expanded(
                  child: TextWidget(
                    text: count == 0 ? 'Chưa chọn' : '$count đã chọn',
                    color: AppColors.white,
                    textStyle: AppTextStyle.semiBold14,
                  ),
                ),
                // Select All / Deselect All
                TextButton(
                  onPressed: controller.toggleSelectAll,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDim,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: TextWidget(
                    text: isAll ? 'Bỏ chọn' : 'Tất cả',
                    color: AppColors.primaryDim,
                    textStyle: AppTextStyle.semiBold14,
                  ),
                ),

                // Share button (when 1 link is selected)
                if (count == 1)
                  IconButton(
                    icon: AppVectors.icSharedCategory.show(size: 22, color: AppColors.primary),
                    onPressed: () {
                      final selectedId = controller.selectedIds.first;
                      final link = controller.listLink.firstWhereOrNull((l) => l.id == selectedId);
                      if (link != null) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: AppColors.transparent,
                          builder: (_) => ShareLinkSheet(link: link),
                        );
                      }
                    },
                    tooltip: 'share_link'.tr,
                  ),

                // Delete button
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: count > 0 ? 1.0 : 0.3,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    onPressed: count > 0 ? controller.deleteSelectedLinks : null,
                    tooltip: 'Xóa đã chọn',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
