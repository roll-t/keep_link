import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';
import 'package:keep_link/core/ui/button/primary_button.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/ui/text_field/simple_input_textfield.dart';
import 'package:keep_link/features/category/presentation/controller/category_controller.dart';

class CategoryDialog extends GetView<CategoryController> {
  static String routeName = '/category_dialog';
  final bool isEditMode;
  const CategoryDialog({super.key, this.isEditMode = false});
  void _initController() {
    final selectedName = controller.popupController.selectedItem.value?.name ?? "";
    controller.errorMess.value = "";
    if (isEditMode) {
      controller.categoryNameController.text = selectedName;
    } else {
      controller.categoryNameController.clear();
    }
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          isMaxParent: true,
          text: isEditMode ? "Save".tr : "Add".tr,
          onPressed: isEditMode ? controller.updateCategory : controller.addCategory,
        ),
        if (isEditMode) const SizedBox(height: 8),
        if (isEditMode)
          PrimaryButton(
            isMaxParent: true,
            text: "Delete".tr,
            onPressed: controller.deleteCategory,
            backgroundColor: AppColors.d300,
            color: AppColors.red,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _initController());
    return Scaffold(
      backgroundColor: AppColors.black.withOpacityCompat(0.6),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.d500, borderRadius: BorderRadius.circular(8)),
          width: Get.width * .9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextWidget(
                      text: isEditMode ? "Edit Category".tr : "Add Category".tr,
                      textStyle: AppTextStyle.medium24,
                      color: AppColors.primary,
                    ),
                    AppVectors.icClose.show(
                      backgroundColor: AppColors.d300,
                      padding: EdgeInsets.all(8),
                      onTap: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (AppGetStorage.isCategorySecurity()) ...[
                  _buildVisibilitySelector(),
                  const SizedBox(height: 28),
                ],
                Obx(
                  () => SimpleInputTextField(
                    controller: controller.categoryNameController,
                    hintText: "Enter category name".tr,
                    errorText: controller.errorMess.value,
                    onChanged: (_) => controller.onChangeDismissError(),
                  ),
                ),
                const SizedBox(height: 20),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilitySelector() {
    return Obx(() {
      final isPublic = controller.visibility.value == VisibilityStatus.public;
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.d300, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            _visibilityItem(
              label: "Public".tr,
              icon: Icons.public,
              selected: isPublic,
              onTap: () => controller.setVisibility(VisibilityStatus.public),
            ),
            _visibilityItem(
              label: "Private".tr,
              icon: Icons.lock,
              selected: !isPublic,
              onTap: () => controller.setVisibility(VisibilityStatus.private),
            ),
          ],
        ),
      );
    });
  }

  Widget _visibilityItem({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? AppColors.white : AppColors.t300),
              const SizedBox(width: 8),
              TextWidget(
                text: label,
                textStyle: AppTextStyle.semiBold14,
                color: selected ? AppColors.white : AppColors.t300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
