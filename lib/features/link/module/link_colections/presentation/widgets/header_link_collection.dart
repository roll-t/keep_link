import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/service/firebase_service.dart';
import 'package:keep_link/features/category/presentation/controller/category_controller.dart';
import 'package:keep_link/features/category/presentation/widget/category_dialog.dart';
import 'package:keep_link/features/category/presentation/widget/custom_popup_widget.dart';
import 'package:keep_link/features/category/presentation/widget/share_category_sheet.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/header_link_collection_controller.dart';

class HeaderLinkCollection extends StatelessWidget {
  const HeaderLinkCollection({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<CategoryController>();
    final headerController = Get.find<HeaderLinkCollectionController>();

    return Positioned(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 40),
        child: Row(
          spacing: 12,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppVectors.icFriends.show(
              size: 28,
              backgroundColor: AppColors.d300,
              padding: const EdgeInsets.all(10),
              widthParent: 44,
              onTap: headerController.openFriends,
            ),
            CustomPopupWidget(
              controller: categoryController.popupController,
              onSelected: categoryController.onSelectedCategory,
            ),
            Row(
              children: [
                Obx(
                  () =>
                      (categoryController.popupController.selectedItem.value?.id == "all" ||
                          categoryController.popupController.items.length <= 1)
                      ? SizedBox.shrink()
                      : Row(
                          children: [
                            AppVectors.icEdit.show(
                              size: 28,
                              backgroundColor: AppColors.d300,
                              padding: const EdgeInsets.all(8),
                              widthParent: 44,
                              onTap: () {
                                Get.dialog(CategoryDialog(isEditMode: true));
                              },
                            ),
                            SizedBox(width: 12),
                            // Share category button (only for signed-in users)
                            if (FirebaseService.currentUser != null)
                              GestureDetector(
                                onTap: () {
                                  final selected =
                                      categoryController.popupController.selectedItem.value;
                                  if (selected == null || selected.id == 'all') return;
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: AppColors.d500,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                    ),
                                    builder: (_) => ShareCategorySheet(
                                      categoryId: selected.id ?? '',
                                      categoryName: selected.name ?? '',
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: AppColors.d300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    size: 24,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            if (FirebaseService.currentUser != null) SizedBox(width: 12),
                          ],
                        ),
                ),
                AppVectors.icAdd.show(
                  size: 28,
                  backgroundColor: AppColors.d300,
                  padding: const EdgeInsets.all(8),
                  widthParent: 44,
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
