import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/presentation/widgets/button/primary_button.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/presentation/widgets/text_field/simple_input_textfield.dart';
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Đưa cả nút back hệ thống đi qua onCancel() thay vì pop mặc định —
        // onCancel() xử lý riêng trường hợp mở thẳng từ share (thoát hẳn app
        // qua SystemNavigator.pop trên Android thay vì pop về màn trống phía
        // sau, vì lúc đó không có route nào để quay lại).
        if (didPop) return;
        addController.onCancel();
      },
      child: Scaffold(
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
            suffixIcon: controller.linkText.value.isNotEmpty
                ? AppVectors.icClose.show(
                    padding: const EdgeInsets.all(12),
                    onTap: () {
                      controller.linkController.clear();
                      controller.onChangeLink('');
                    },
                  )
                : AppVectors.icClipBoard.show(
                    padding: const EdgeInsets.all(12),
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
    return Obx(() {
      final saving = controller.isSaving.value;
      return Row(
        spacing: 20,
        children: [
          Expanded(
            child: PrimaryButton(
              isMaxParent: true,
              text: "Huỷ",
              backgroundColor: AppColors.d300,
              color: AppColors.red,
              // Khoá luôn nút Huỷ trong lúc đang lưu — thoát giữa chừng lúc
              // request insert/update còn dang dở dễ tạo trạng thái mập mờ.
              onPressed: saving ? null : controller.onCancel,
            ),
          ),
          Expanded(
            child: PrimaryButton(
              isMaxParent: true,
              text: "Lưu",
              isLoading: saving,
              onPressed: controller.onSave,
            ),
          ),
        ],
      );
    });
  }
}
