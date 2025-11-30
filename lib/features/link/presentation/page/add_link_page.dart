import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/ui/button/primary_button.dart';
import 'package:keep_link/core/ui/popup/custom_popup_widget.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/ui/text_field/simple_input_textfield.dart';
import 'package:keep_link/features/link/application/controller/header_link_collection_controller.dart';
import 'package:keep_link/features/link/presentation/widget/category_dialog.dart';

class AddLinkPage extends GetView<HeaderLinkCollectionController> {
  static String routeName = "/AddLinkPage";
  const AddLinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12).copyWith(top: 40),
        child: Column(
          spacing: 28,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWidget(
                  text: "Thêm Link",
                  textStyle: AppTextStyle.semiBold20,
                  color: AppColors.primary,
                ),
                Row(
                  spacing: 12,
                  children: [
                    CustomPopupWidget(controller: controller.popupController),
                    Row(
                      spacing: 12,
                      children: [
                        AppVectors.icAdd.show(
                          size: 28,
                          backgroundColor: AppColors.d200,
                          padding: const EdgeInsets.all(8),
                          onTap: () {
                            Get.dialog(CategoryDialog());
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Column(
              spacing: 20,
              children: [
                SimpleInputTextField(
                  label: "Link",
                  hintText: "Nhập link",
                  controller: controller.linkController,
                  suffixIcon: AppVectors.icClipBoard.show(
                    padding: EdgeInsets.all(10),
                    onTap: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data != null && data.text != null) {
                        controller.linkController.text = data.text!;
                        Fluttertoast.showToast(msg: "Đã dán");
                      } else {
                        Fluttertoast.showToast(msg: "Chưa có dữ liệu");
                      }
                    },
                  ),
                ),
                SimpleInputTextField(label: "Tiêu đề", hintText: "Nhập tiêu đề"),
                Row(
                  spacing: 20,
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        isMaxParent: true,
                        text: "Huỷ",
                        onPressed: () => Get.back(),
                        backgroundColor: AppColors.d200,
                        color: AppColors.red,
                      ),
                    ),
                    Expanded(
                      child: PrimaryButton(isMaxParent: true, text: "Lưu", onPressed: () {}),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
