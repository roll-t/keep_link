import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/library/custom_popup.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/category/application/controller/custom_popup_controller.dart';

class CustomPopupWidget extends StatelessWidget {
  final VoidCallback? onSelected;
  final CustomPopupController controller;
  final bool hasAll;

  const CustomPopupWidget({
    super.key,
    required this.controller,
    this.onSelected,
    this.hasAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      constraints: BoxConstraints(minWidth: Get.width * .3, maxWidth: Get.width * .45),
      decoration: BoxDecoration(color: AppColors.d200, borderRadius: BorderRadius.circular(100)),
      alignment: Alignment.center,
      child: Obx(() {
        final RxString displayTitle =
            (hasAll
                    ? controller.selectedItem.value?.name ?? "Chọn danh mục"
                    : (controller.selectedItem.value?.id == 'all'
                          ? "Chọn danh mục"
                          : controller.selectedItem.value?.name ?? "Chọn danh mục"))
                .obs;
        return CustomPopup(
          barrierColor: Colors.transparent,
          showArrow: false,
          arrowColor: AppColors.white,
          position: PopupPosition.bottom,
          onAfterPopup: () => controller.isOpen.value = false,
          onBeforePopup: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.isOpen.value = true;
              controller.scrollToSelected();
            });
          },

          // ===== POPUP CONTENT =====
          contentDecoration: BoxDecoration(
            color: AppColors.d200,
            borderRadius: BorderRadius.circular(12),
          ),
          content: Builder(
            builder: (context) {
              final displayItems = hasAll
                  ? controller.items
                  : controller.items.where((e) => e.id != 'all').toList();

              return Container(
                width: Get.width * .7,
                constraints: BoxConstraints(
                  maxHeight: displayItems.length > controller.maxItemDisplay
                      ? controller.itemHeight * controller.maxItemDisplay
                      : displayItems.length * controller.itemHeight,
                ),
                child: ListView.builder(
                  controller: controller.scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: displayItems.length,
                  itemBuilder: (context, index) {
                    final item = displayItems[index];
                    final isSelected = controller.selectedItem.value?.id == item.id;
                    final isLastItem = index == displayItems.length - 1;
                    return GestureDetector(
                      onTap: () {
                        controller.selectItem(item);
                        onSelected?.call();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        height: controller.itemHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          border: !isLastItem
                              ? Border(bottom: BorderSide(color: AppColors.d100))
                              : null,
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
              );
            },
          ),

          // ===== BUTTON =====
          child: Container(
            padding: const EdgeInsets.only(left: 14, right: 8),
            height: controller.itemHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextWidget(
                    text: displayTitle.value,
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
