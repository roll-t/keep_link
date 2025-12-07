import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/features/category/application/controller/category_controller.dart';
import 'package:keep_link/features/category/presentation/widget/category_dialog.dart';
import 'package:keep_link/features/category/presentation/widget/custom_popup_widget.dart';
import 'package:keep_link/features/link/application/controller/link_collection_controller.dart';
import 'package:keep_link/features/setting/presentation/page/setting_page.dart';

class HeaderLinkCollection extends GetView<CategoryController> {
  const HeaderLinkCollection({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 40),
        child: Row(
          spacing: 12,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppVectors.icSetting.show(
              size: 28,
              backgroundColor: AppColors.d200,
              padding: const EdgeInsets.all(8),
              onTap: () {
                Get.toNamed(SettingPage.routeName);
              },
            ),
            CustomPopupWidget(
              controller: controller.popupController,
              onSelected: () {
                DependencyUtils.find<LinkCollectionController>()?.fetchAllLinks();
              },
            ),
            Row(
              children: [
                Obx(
                  () =>
                      (controller.popupController.selectedItem.value?.id == "all" ||
                          controller.popupController.items.length <= 1)
                      ? SizedBox.shrink()
                      : Row(
                          children: [
                            AppVectors.icEdit.show(
                              size: 28,
                              backgroundColor: AppColors.d200,
                              padding: const EdgeInsets.all(8),
                              onTap: () {
                                // edit
                                Get.dialog(CategoryDialog(isEditMode: true));
                              },
                            ),
                            SizedBox(width: 12),
                          ],
                        ),
                ),
                AppVectors.icAdd.show(
                  size: 28,
                  backgroundColor: AppColors.d200,
                  padding: const EdgeInsets.all(8),
                  onTap: () {
                    // add
                    Get.dialog(CategoryDialog());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
