import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/ui/popup/custom_popup_widget.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/link/application/controller/header_link_collection_controller.dart';

class HeaderLinkCollection extends GetView<HeaderLinkCollectionController> {
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
                AppVectors.icEdit.show(
                  size: 28,
                  backgroundColor: AppColors.d200,
                  padding: const EdgeInsets.all(8),
                ),
                AppVectors.icAdd.show(
                  size: 28,
                  backgroundColor: AppColors.d200,
                  padding: const EdgeInsets.all(8),
                  onTap: () {
                    Get.dialog(
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.d300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          width: Get.width * .9,

                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 20,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextWidget(
                                    text: "Thêm danh mục",
                                    textStyle: AppTextStyle.medium24,
                                  ),
                                  AppVectors.icClose.show(onTap: () => Get.back()),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
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
