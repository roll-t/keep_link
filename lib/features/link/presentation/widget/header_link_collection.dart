import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/link/presentation/widget/custom_popup.dart';

class HeaderLinkCollection extends StatelessWidget {
  HeaderLinkCollection({super.key});

  // Rx để lưu item đã chọn
  final selectedItem = "popup".obs;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 40),
        child: Row(
          spacing: 20,
          children: [
            /// Nút setting
            AppVectors.icSetting.show(
              size: 28,
              backgroundColor: AppColors.d200,
              padding: const EdgeInsets.all(8),
            ),

            /// Popup chọn item
            Expanded(
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: AppColors.d200,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => CustomPopup(
                          barrierColor: Colors.transparent,
                          showArrow: false,
                          arrowColor: AppColors.white,
                          position: PopupPosition.bottom,
                          contentDecoration: BoxDecoration(
                            color: AppColors.d200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: Container(
                            width: Get.width * .7,
                            constraints: BoxConstraints(maxHeight: Get.width * .8),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: 30,
                              itemBuilder: (context, i) {
                                final itemText = "Item $i";
                                return GestureDetector(
                                  onTap: () {
                                    selectedItem.value = itemText; // lưu item đã chọn
                                    // đóng popup khi chọn
                                    Navigator.of(context).pop();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(width: 1, color: AppColors.d100),
                                      ),
                                      color: selectedItem.value == itemText
                                          ? AppColors.d100
                                          : Colors.transparent,
                                    ),
                                    child: TextWidget(text: itemText),
                                  ),
                                );
                              },
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextWidget(text: selectedItem.value),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// Nút add
            AppVectors.icAdd.show(
              size: 28,
              backgroundColor: AppColors.d200,
              padding: const EdgeInsets.all(8),
            ),
          ],
        ),
      ),
    );
  }
}
