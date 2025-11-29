import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/library/custom_popup.dart';
import 'package:keep_link/core/ui/popup/custom_popup_controller.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';

class CustomPopupWidget extends StatelessWidget {
  const CustomPopupWidget({super.key, required this.controller});

  final CustomPopupController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      constraints: BoxConstraints(minWidth: Get.width * .3, maxWidth: Get.width * .45),
      decoration: BoxDecoration(color: AppColors.d200, borderRadius: BorderRadius.circular(100)),
      alignment: Alignment.center,
      child: Obx(() {
        return CustomPopup(
          barrierColor: Colors.transparent,
          showArrow: false,
          arrowColor: AppColors.white,
          position: PopupPosition.bottom,
          onAfterPopup: () {
            controller.isOpen.value = false;
          },
          onBeforePopup: () {
            controller.isOpen.value = true;
            controller.scrollToSelected();
          },

          contentDecoration: BoxDecoration(
            color: AppColors.d200,
            borderRadius: BorderRadius.circular(12),
          ),

          // ------ POPUP LIST ------
          content: Container(
            width: Get.width * .7,
            constraints: BoxConstraints(maxHeight: Get.width * .8),
            child: ListView.builder(
              controller: controller.scrollController,
              padding: EdgeInsets.zero,
              itemCount: controller.items.length,
              itemBuilder: (context, i) {
                final item = controller.items[i];
                final isSelected = controller.selectedItem.value?.id == item.id;

                return GestureDetector(
                  onTap: () {
                    controller.selectItem(item);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    height: controller.itemHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.d100)),
                      color: isSelected ? AppColors.d100 : Colors.transparent,
                    ),
                    child: TextWidget(
                      text: item.name ?? "",
                      maxLines: 1,
                      textStyle: AppTextStyle.semiBold16,
                    ),
                  ),
                );
              },
            ),
          ),

          // ------ BUTTON INSIDE CONTAINER ------
          child: Container(
            padding: const EdgeInsets.only(left: 14, right: 8),
            height: controller.itemHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextWidget(
                    text: controller.selectedItem.value?.name ?? "Select Item",
                    maxLines: 1,
                    textStyle: AppTextStyle.semiBold16,
                  ),
                ),
                Obx(() {
                  return AnimatedRotation(
                    turns: controller.isOpen.value ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: AppVectors.icArrowDown.show(color: AppColors.t300),
                  );
                }),
              ],
            ),
          ),
        );
      }),
    );
  }
}
