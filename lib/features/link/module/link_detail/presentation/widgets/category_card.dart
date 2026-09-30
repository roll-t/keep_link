import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/list_title_widget.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/link_detail_controller.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/change_category_sheet.dart';

class CategoryCard extends GetView<LinkDetailController> {
  const CategoryCard({super.key});
  @override
  Widget build(BuildContext context) {
    if (!controller.isMine) return const SizedBox.shrink();
    return Obx(() {
      final category = controller.currentCategory;
      final hasCategory = category != null;
      return Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        child: ListTitleWidget(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          onTap: () {
            if (controller.readOnly) {
              controller.showReadOnlyMessage();
              return;
            }
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.transparent,
              builder: (_) => ChangeCategorySheet(controller: controller),
            );
          },
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacityCompat(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.folder_outlined,
              color: hasCategory ? AppColors.primaryBright : AppColors.white70,
              size: 22,
            ),
          ),
          title: hasCategory ? (category.name ?? "Folder".tr) : "Folder".tr,
          subtitle: hasCategory
              ? "Tap to move to another category".tr
              : "Add this post to a category".tr,
          trailing: Icon(
            hasCategory ? Icons.drive_file_move_outlined : Icons.create_new_folder_outlined,
            size: 20,
            color: AppColors.white70,
          ),
        ),
      );
    });
  }
}
