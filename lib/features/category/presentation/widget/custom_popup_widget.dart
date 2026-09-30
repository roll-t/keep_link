import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/data/models/item_model.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/popup/custom_popup.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/utils/link_source_util.dart';
import 'package:keep_link/features/category/presentation/controller/custom_popup_controller.dart';

class CustomPopupWidget extends StatelessWidget {
  final VoidCallback? onSelected;
  final CustomPopupController controller;
  final bool hasAll;
  final String? allLabel;
  final bool hasSources;

  const CustomPopupWidget({
    super.key,
    required this.controller,
    this.onSelected,
    this.hasAll = true,
    this.allLabel,
    this.hasSources = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      String nameWithCount(ItemModel? item, String fallback) {
        if (item == null) return fallback;
        final base = item.id == 'all' && allLabel != null ? allLabel! : (item.name ?? fallback);
        if (item.id == 'all') return base;
        final count = item.chilrenCount;
        return count != null ? '$base ($count)' : base;
      }

      final selected = controller.selectedItem.value;
      final displayTitle = hasAll
          ? nameWithCount(selected, "Select Category".tr)
          : (selected?.id == 'all'
                ? "Select Category".tr
                : nameWithCount(selected, "Select Category".tr));

      return CustomPopup(
        barrierColor: AppColors.transparent,
        showArrow: false,
        arrowColor: AppColors.white,
        position: PopupPosition.bottom,
        verticalOffset: 8,
        onAfterPopup: () => controller.isOpen.value = false,
        onBeforePopup: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.isOpen.value = true;
            if (controller.selectedItem.value?.isSource == true) {
              controller.activeTab.value = 1;
            } else if (controller.selectedItem.value?.id != 'all') {
              controller.activeTab.value = 0;
            }
            controller.scrollToSelected();
          });
        },

        // ===== POPUP CONTENT =====
        contentDecoration: BoxDecoration(
          color: AppColors.navigationSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        content: Builder(
          builder: (context) {
            return Obx(() {
              final isSourcesTab = hasSources && controller.activeTab.value == 1;
              final rawItems = isSourcesTab ? controller.sourceItems : controller.items;
              final displayItems = hasAll
                  ? rawItems
                  : rawItems.where((e) => e.id != 'all').toList();

              final maxCount = displayItems.length > controller.maxItemDisplay
                  ? controller.maxItemDisplay
                  : (displayItems.isEmpty ? 1 : displayItems.length);
              final listHeight = maxCount * controller.itemHeight;

              return AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: Container(
                  width: Get.width * .7,
                  constraints: BoxConstraints(
                    maxHeight: hasSources ? (listHeight + 46) : listHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasSources)
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.white.withOpacityCompat(0.08),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildTabItem(
                                label: "Categories".tr,
                                count: controller.items.where((e) => e.id != 'all').length,
                                isSelected: controller.activeTab.value == 0,
                                onTap: () {
                                  if (controller.activeTab.value != 0) {
                                    controller.activeTab.value = 0;
                                  }
                                },
                              ),
                              _buildTabItem(
                                label: "Sources".tr,
                                count: controller.sourceItems.length,
                                isSelected: controller.activeTab.value == 1,
                                onTap: () {
                                  if (controller.activeTab.value != 1) {
                                    controller.activeTab.value = 1;
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      if (displayItems.isEmpty)
                        Container(
                          height: controller.itemHeight,
                          alignment: Alignment.center,
                          child: TextWidget(
                            text: isSourcesTab ? 'No sources found'.tr : 'No categories found'.tr,
                            color: AppColors.white70,
                            textStyle: AppTextStyle.regular12,
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.builder(
                            key: ValueKey('popup_list_${controller.activeTab.value}'),
                            controller: controller.scrollController,
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: displayItems.length,
                            itemBuilder: (context, index) {
                              final item = displayItems[index];
                              final isSelected = controller.selectedItem.value?.id == item.id;
                              final isLastItem = index == displayItems.length - 1;
                              return GestureDetector(
                                onTap: () async {
                                  final nav = Navigator.of(context);
                                  final didSelect = await controller.selectItem(item);
                                  if (!didSelect) return;
                                  nav.pop();
                                  onSelected?.call();
                                },
                                child: Container(
                                  height: controller.itemHeight,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    border: !isLastItem
                                        ? Border(
                                            bottom: BorderSide(
                                              color: AppColors.white.withValues(alpha: .1),
                                            ),
                                          )
                                        : null,
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: .14)
                                        : AppColors.transparent,
                                  ),
                                  child: Row(
                                    children: [
                                      if (item.isSource && item.sourceHost != null) ...[
                                        Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: AppColors.white.withOpacityCompat(0.06),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          alignment: Alignment.center,
                                          child: LinkSourceUtil.sourceIcon(
                                            item.sourceHost!,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: TextWidget(
                                          text: item.id == 'all'
                                              ? (allLabel ?? item.name ?? '')
                                              : (item.name ?? ''),
                                          maxLines: 1,
                                          textStyle: AppTextStyle.semiBold14,
                                        ),
                                      ),
                                      if (item.chilrenCount != null && item.id != 'all')
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.white.withOpacityCompat(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: TextWidget(
                                            text: '${item.chilrenCount}',
                                            color: AppColors.white,
                                            textStyle: AppTextStyle.semiBold12,
                                          ),
                                        ),
                                      if (item.visibility == VisibilityStatus.private &&
                                          controller.isEnableSecurity.value)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(Icons.lock, size: 16, color: AppColors.t300),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            });
          },
        ),

        // ===== BUTTON =====
        child: Container(
          height: 40,
          constraints: BoxConstraints(minWidth: Get.width * .3, maxWidth: Get.width * .45),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.navigationSurface,
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected?.isSource == true && selected?.sourceHost != null) ...[
                LinkSourceUtil.sourceIcon(selected!.sourceHost!, size: 16),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: TextWidget(
                  text: displayTitle,
                  maxLines: 1,
                  textStyle: AppTextStyle.semiBold14,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTabItem({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? AppColors.white : AppColors.n70,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 7),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 2,
                    width: isSelected ? (label.length >= 6 ? 48.0 : 36.0) : 0.0,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
