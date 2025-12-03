import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/ui/button/primary_button.dart';
import 'package:keep_link/core/ui/popup/custom_popup_widget.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/ui/text_field/simple_input_textfield.dart';
import 'package:keep_link/features/link/application/controller/add_link_controller.dart';
import 'package:keep_link/features/link/application/controller/category_controller.dart';
import 'package:keep_link/features/link/presentation/widget/category_dialog.dart';
import 'package:keep_link/features/link/presentation/widget/deep_link_preview.dart';

class AddLinkPage extends StatelessWidget {
  static String routeName = "/AddLinkPage";
  const AddLinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12).copyWith(top: 40),
        child: Column(
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            const DeepLinkPreview(),
            SizedBox(height: 4),
            GetBuilder<AddLinkController>(
              builder: (controller) {
                return Column(
                  children: [
                    SizedBox(height: 4),
                    Obx(
                      () => SimpleInputTextField(
                        label: "Link",
                        hintText: "Nhập link",
                        controller: controller.linkController,
                        errorText: controller.errorLinkMess.value,
                        onChanged: controller.onChangeLink,
                        suffixIcon: AppVectors.icClipBoard.show(
                          padding: const EdgeInsets.all(10),
                          onTap: controller.onPasteClipboard,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Obx(
                      () => SimpleInputTextField(
                        controller: controller.titleController,
                        label: "Tiêu đề",
                        hintText: "Nhập tiêu đề",
                        onChanged: controller.onChangeTitle,
                        errorText: controller.errorTitleMess.value,
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildActionButtons(controller),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GetBuilder<AddLinkController>(
          builder: (controller) {
            return Obx(
              () => TextWidget(
                text: controller.isEditModel.value ? "Chỉnh sửa" : "Thêm Link",
                textStyle: AppTextStyle.semiBold20,
                color: AppColors.primary,
              ),
            );
          },
        ),
        GetBuilder<CategoryController>(
          builder: (controller) {
            return Row(
              spacing: 12,
              children: [
                CustomPopupWidget(controller: controller.popupController),
                AppVectors.icAdd.show(
                  size: 28,
                  backgroundColor: AppColors.d200,
                  padding: const EdgeInsets.all(8),
                  onTap: () => Get.dialog(const CategoryDialog()),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(AddLinkController controller) {
    return Row(
      spacing: 20,
      children: [
        Expanded(
          child: PrimaryButton(
            isMaxParent: true,
            text: "Huỷ",
            backgroundColor: AppColors.d300,
            color: AppColors.red,
            onPressed: controller.onCancel,
          ),
        ),
        Expanded(
          child: PrimaryButton(isMaxParent: true, text: "Lưu", onPressed: controller.onSave),
        ),
      ],
    );
  }
}
