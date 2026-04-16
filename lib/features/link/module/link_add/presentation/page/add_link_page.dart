import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/ui/button/primary_button.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/ui/text_field/simple_input_textfield.dart';
import 'package:keep_link/features/category/presentation/controller/category_controller.dart';
import 'package:keep_link/features/category/presentation/widget/category_dialog.dart';
import 'package:keep_link/features/category/presentation/widget/custom_popup_widget.dart';
import 'package:keep_link/features/link/module/link_add/presentation/controller/add_link_controller.dart';
import 'package:keep_link/features/link/module/link_add/presentation/widgets/deep_link_preview.dart';

class AddLinkPage extends StatelessWidget {
  static String routeName = "/AddLinkPage";

  const AddLinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final addController = Get.find<AddLinkController>();
    final categoryController = Get.find<CategoryController>();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12).copyWith(top: 40),
        child: Column(
          children: [
            _buildHeader(addController, categoryController),
            const SizedBox(height: 24),
            const DeepLinkPreview(),
            const SizedBox(height: 12),
            _buildForm(addController),
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader(AddLinkController addController, CategoryController categoryController) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Obx(
          () => TextWidget(
            text: addController.isEditModel.value ? "Chỉnh sửa" : "Thêm Link",
            textStyle: AppTextStyle.semiBold20,
            color: AppColors.primary,
          ),
        ),

        Row(
          spacing: 12,
          children: [
            CustomPopupWidget(controller: categoryController.popupController, hasAll: false),
            AppVectors.icAdd.show(
              size: 28,
              backgroundColor: AppColors.d200,
              padding: const EdgeInsets.all(8),
              onTap: () => Get.dialog(const CategoryDialog()),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- FORM INPUT ----------------
  Widget _buildForm(AddLinkController controller) {
    return Column(
      children: [
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
        const SizedBox(height: 20),

        Obx(
          () => SimpleInputTextField(
            controller: controller.titleController,
            label: "Tiêu đề",
            hintText: "Nhập tiêu đề",
            maxLine: 4,
            height: 80,
            contentPadding: EdgeInsets.only(top: 12, left: 12, right: 12),
            onChanged: controller.onChangeTitle,
            errorText: controller.errorTitleMess.value,
          ),
        ),
        const SizedBox(height: 28),

        _buildActionButtons(controller),
      ],
    );
  }

  // ---------------- BOTTOM BUTTONS ----------------
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
