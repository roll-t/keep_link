import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/ui/button/primary_button.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/ui/text_field/simple_input_textfield.dart';
import 'package:keep_link/features/category/application/controller/category_controller.dart';

class CategoryDialog extends GetView<CategoryController> {
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
          text: isEditMode ? "Lưu" : "Thêm",
          onPressed: isEditMode ? controller.updateCategory : controller.addCategory,
        ),
        if (isEditMode) const SizedBox(height: 8),
        if (isEditMode)
          PrimaryButton(
            isMaxParent: true,
            text: "Xoá",
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
    return Material(
      color: Colors.transparent,
      child: Center(
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
                      text: isEditMode ? "Chỉnh sửa danh mục" : "Thêm danh mục",
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
                Obx(
                  () => SimpleInputTextField(
                    controller: controller.categoryNameController,
                    hintText: "Nhập tên danh mục",
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
}
