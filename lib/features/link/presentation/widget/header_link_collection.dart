import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/ui/popup/custom_popup_widget.dart';
import 'package:keep_link/features/link/application/controller/category_controller.dart';
import 'package:keep_link/features/link/presentation/widget/category_dialog.dart';

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
            ),
            CustomPopupWidget(controller: controller.popupController),
            Row(
              spacing: 12,
              children: [
                Obx(
                  () => controller.popupController.selectedItem.value?.id == "all"
                      ? SizedBox.shrink()
                      : AppVectors.icEdit.show(
                          size: 28,
                          backgroundColor: AppColors.d200,
                          padding: const EdgeInsets.all(8),
                          onTap: () {
                            // edit
                            Get.dialog(CategoryDialog(isEditMode: true));
                          },
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
