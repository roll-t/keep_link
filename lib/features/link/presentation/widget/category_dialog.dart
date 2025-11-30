import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/ui/button/primary_button.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/ui/text_field/simple_input_textfield.dart';

class CategoryDialog extends StatelessWidget {
  final bool isEditMode;
  const CategoryDialog({super.key, this.isEditMode = false});

  @override
  Widget build(BuildContext context) {
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
              spacing: 20,
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
                    AppVectors.icClose.show(onTap: () => Get.back()),
                  ],
                ),
                SimpleInputTextField(hintText: "Nhập tên danh mục"),
                Column(
                  spacing: 8,
                  children: [
                    PrimaryButton(isMaxParent: true, text: "Thêm", onPressed: () {}),
                    if (isEditMode)
                      PrimaryButton(
                        isMaxParent: true,
                        text: "Xoá",
                        onPressed: () {},
                        backgroundColor: AppColors.d200,
                        color: AppColors.red,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
