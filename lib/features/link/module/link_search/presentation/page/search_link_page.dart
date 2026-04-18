import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/ui/text_field/simple_input_textfield.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/widgets/link_item.dart';
import 'package:keep_link/features/link/module/link_search/presentation/controller/search_link_controller.dart';

class SearchLinkPage extends GetView<SearchLinkController> {
  static String routeName = '/SearchLinkPage';
  const SearchLinkPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg700,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _SearchBar(ctrl: controller),
            const SizedBox(height: 12),
            _CategorySection(ctrl: controller),
            const SizedBox(height: 20),
            Expanded(child: _ResultBody(ctrl: controller)),
          ],
        ),
      ),
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final SearchLinkController ctrl;
  const _SearchBar({required this.ctrl});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          InkWell(onTap: () => Get.back(), child: const Icon(Icons.arrow_back_ios_new_rounded)),
          SizedBox(width: 12),
          Expanded(
            child: SimpleInputTextField(
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.white.withOpacityCompat(0.3),
              ),
              hintText: 'Search links'.tr,
              controller: ctrl.searchTec,
              backgroundColor: AppColors.d300,
              enableColor: AppColors.white.withOpacityCompat(0.08),
              focusedColor: AppColors.primary.withOpacityCompat(0.3),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showFilterSheet(context, ctrl),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.d300,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.white.withOpacityCompat(0.08)),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: AppColors.white.withOpacityCompat(0.5),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ─── Category chips ───────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final SearchLinkController ctrl;
  const _CategorySection({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final cats = ctrl.categories;

          return SingleChildScrollView(
            controller: ctrl.categoryScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Chip "All"
                _ScrollItem(
                  onSelected: () => ctrl.selectCategory(null),
                  child: _CategoryChip(
                    label: 'All',
                    selected: ctrl.selectedCategoryId.value == null,
                  ),
                ),
                ...cats.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _ScrollItem(
                      onSelected: () => ctrl.selectCategory(cat.id),
                      child: Obx(
                        () => _CategoryChip(
                          label: cat.name ?? '',
                          selected: ctrl.selectedCategoryId.value == cat.id,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Wrapper widget to handle "Scroll to center" logic
class _ScrollItem extends StatelessWidget {
  final Widget child;
  final VoidCallback onSelected;

  const _ScrollItem({required this.child, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onSelected();
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      },
      child: child,
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  // Remove VoidCallback onTap as the wrapper already handles it

  const _CategoryChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    // REMOVE GestureDetector here
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.bg500,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.white.withOpacityCompat(0.12),
        ),
      ),
      child: TextWidget(
        text: label,
        color: selected ? AppColors.white : AppColors.white.withOpacityCompat(0.55),
        size: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}

// ─── Result body ──────────────────────────────────────────────────────────────

class _ResultBody extends StatelessWidget {
  final SearchLinkController ctrl;
  const _ResultBody({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Loading
      if (ctrl.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
        );
      }

      // No results while searching
      if (ctrl.searchResults.isEmpty && ctrl.searchText.value.isNotEmpty) {
        return _EmptyState(icon: AppVectors.icSearchNotFound, message: 'No matching results found');
      }

      // No links in database
      if (ctrl.searchResults.isEmpty) {
        return _EmptyState(
          icon: AppVectors.icSearchFile,
          message: 'No links yet\nAdd your first link!',
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: ctrl.searchResults.length,
        itemBuilder: (_, i) => LinkItem(index: i, item: ctrl.searchResults[i]),
      );
    });
  }
}

class _EmptyState extends StatelessWidget {
  final dynamic icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon.show(color: AppColors.white.withOpacityCompat(0.15), size: Get.width * .28),
          const SizedBox(height: 16),
          TextWidget(
            text: message,
            textAlign: TextAlign.center,
            color: AppColors.white.withOpacityCompat(0.35),
            size: 15,
          ),
        ],
      ),
    );
  }
}

// ─── Filter bottom sheet ──────────────────────────────────────────────────────

void _showFilterSheet(BuildContext context, SearchLinkController ctrl) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg500,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FilterSheet(ctrl: ctrl),
  );
}

class _FilterSheet extends StatelessWidget {
  final SearchLinkController ctrl;
  const _FilterSheet({required this.ctrl});

  static const _sortOptions = [
    (SortOption.newest, 'Newest', Icons.arrow_downward_rounded),
    (SortOption.oldest, 'Oldest', Icons.arrow_upward_rounded),
    (SortOption.nameAZ, 'Name A → Z', Icons.sort_by_alpha_rounded),
    (SortOption.nameZA, 'Name Z → A', Icons.sort_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacityCompat(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const TextWidget(
              text: 'Sort by',
              color: AppColors.white,
              size: 16,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 12),

            Obx(
              () => Column(
                children: _sortOptions.map((opt) {
                  final (value, label, icon) = opt;
                  final selected = ctrl.selectedSort.value == value;
                  return GestureDetector(
                    onTap: () {
                      ctrl.selectSort(value);
                      Get.back();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacityCompat(0.15)
                            : AppColors.white.withOpacityCompat(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary.withOpacityCompat(0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            color: selected
                                ? AppColors.primary
                                : AppColors.white.withOpacityCompat(0.5),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          TextWidget(
                            text: label,
                            color: selected
                                ? AppColors.white
                                : AppColors.white.withOpacityCompat(0.6),
                            size: 15,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          const Spacer(),
                          if (selected)
                            Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Reset button
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                ctrl.selectSort(SortOption.newest);
                ctrl.selectCategory(null);
                Get.back();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacityCompat(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextWidget(
                  text: 'Reset filters',
                  textAlign: TextAlign.center,
                  color: AppColors.n80,
                  size: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
