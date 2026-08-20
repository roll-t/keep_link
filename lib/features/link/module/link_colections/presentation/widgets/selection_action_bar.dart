import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/link_collection_controller.dart';

class SelectionActionBar extends GetView<LinkCollectionController> {
  const SelectionActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final sidePadding = MediaQuery.sizeOf(context).width * 0.04;

    return Obx(() {
      final count = controller.selectedIds.length;
      final isAll = controller.isAllSelected;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: sidePadding),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.d300.withOpacityCompat(0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.white.withOpacityCompat(0.08)),
              ),
              child: Row(
                children: [
                  // Cancel button
                  TextButton(
                    onPressed: controller.exitSelectionMode,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      'Huỷ',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Selected count (center)
                  Expanded(
                    child: Text(
                      count == 0 ? 'Chưa chọn' : '$count đã chọn',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Select All / Deselect All
                  TextButton(
                    onPressed: controller.toggleSelectAll,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDim,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text(
                      isAll ? 'Bỏ chọn' : 'Tất cả',
                      style: const TextStyle(
                        color: AppColors.primaryDim,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Delete button
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: count > 0 ? 1.0 : 0.3,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      onPressed: count > 0 ? controller.deleteSelectedLinks : null,
                      tooltip: 'Xóa đã chọn',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
