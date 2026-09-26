import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/di/dependency_utils.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/appbar/sheet_header.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/category/presentation/controller/category_controller.dart';
import 'package:keep_link/features/category/presentation/widget/category_dialog.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/link_detail_controller.dart';

class ChangeCategorySheet extends StatefulWidget {
  final LinkDetailController controller;

  const ChangeCategorySheet({super.key, required this.controller});

  @override
  State<ChangeCategorySheet> createState() => _ChangeCategorySheetState();
}

class _ChangeCategorySheetState extends State<ChangeCategorySheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateCategoryDialog() {
    Navigator.of(context).pop();
    if (!Get.isRegistered<CategoryController>()) {
      DependencyUtils.put(() => CategoryController());
    }
    Get.dialog(const CategoryDialog(), barrierDismissible: false);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentCatId = widget.controller.currentCategoryId.value;
      final hasCategory = currentCatId != null && currentCatId.isNotEmpty;

      // Lọc danh sách danh mục (bỏ qua 'all')
      final allCategories =
          AppCache.categories.where((c) => c.id != 'all').toList();
      final filteredCategories = _searchQuery.isEmpty
          ? allCategories
          : allCategories
              .where((c) => (c.name ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
              .toList();

      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: AppColors.modalSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // Drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacityCompat(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Header
              SheetHeader(
                title:
                    hasCategory ? "Change Category".tr : "Add to Category".tr,
                subtitle: widget.controller.title.isNotEmpty
                    ? widget.controller.title
                    : null,
                trailing: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.white70,
                    size: 22,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // Search bar if more than 5 categories
              if (allCategories.length > 5) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: AppColors.n70,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) =>
                                setState(() => _searchQuery = val.trim()),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.white,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              hintText: "Select Category".tr,
                              hintStyle: const TextStyle(
                                fontSize: 14,
                                color: AppColors.n70,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(
                              Icons.cancel_rounded,
                              size: 16,
                              color: AppColors.n70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              // Danh sách danh mục
              Flexible(
                child: filteredCategories.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 36, horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.folder_open_rounded,
                              size: 44,
                              color: AppColors.n500,
                            ),
                            const SizedBox(height: 10),
                            TextWidget(
                              text: "No categories available".tr,
                              color: AppColors.n70,
                              textStyle: AppTextStyle.regular14,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filteredCategories.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final category = filteredCategories[index];
                          final isSelected = category.id == currentCatId;
                          final linkCount = category.chilrenCount ??
                              AppCache.links
                                  .where((l) => l.categoryId == category.id)
                                  .length;

                          return InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.controller.changeCategory(category.id);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withOpacityCompat(0.16)
                                    : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                          .withOpacityCompat(0.4)
                                      : AppColors.white.withOpacityCompat(0.04),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                              .withOpacityCompat(0.25)
                                          : AppColors.white
                                              .withOpacityCompat(0.06),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.folder_rounded,
                                      color: isSelected
                                          ? AppColors.primaryBright
                                          : AppColors.white70,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: TextWidget(
                                                text: category.name ?? '',
                                                textStyle:
                                                    AppTextStyle.semiBold14,
                                                color: isSelected
                                                    ? AppColors.primaryBright
                                                    : AppColors.white,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (category.visibility ==
                                                VisibilityStatus.private) ...[
                                              const SizedBox(width: 6),
                                              const Icon(
                                                Icons.lock_rounded,
                                                size: 13,
                                                color: AppColors.warning,
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        TextWidget(
                                          text: '$linkCount links',
                                          textStyle: AppTextStyle.regular12,
                                          color: AppColors.n70,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 8),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 8),

              // Bottom Actions: "Tạo danh mục mới" & "Xóa khỏi danh mục" (nếu có)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nút Tạo danh mục mới
                    InkWell(
                      onTap: _openCreateCategoryDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacityCompat(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                              color: AppColors.primaryBright,
                            ),
                            const SizedBox(width: 8),
                            TextWidget(
                              text: "Create New Category".tr,
                              textStyle: AppTextStyle.semiBold14,
                              color: AppColors.primaryBright,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Nếu link đang có danh mục: nút Bỏ danh mục
                    if (hasCategory) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.controller.changeCategory(null);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 16,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 6),
                              TextWidget(
                                text: "Remove from Category".tr,
                                textStyle: AppTextStyle.semiBold14,
                                color: AppColors.error,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
    });
  }
}
