import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_icons.dart';
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
            Expanded(
              child: Obx(() {
                if (controller.isFieldFocused.value) {
                  return _SuggestionPanel(ctrl: controller);
                }
                return Column(
                  children: [
                    _CategorySection(ctrl: controller),
                    const SizedBox(height: 20),
                    Expanded(child: _ResultBody(ctrl: controller)),
                  ],
                );
              }),
            ),
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
              radius: 1000,
              hintText: 'Search links'.tr,
              controller: ctrl.searchTec,
              focusNode: ctrl.searchFocusNode,
              backgroundColor: AppColors.d300,
              enableColor: AppColors.white.withOpacityCompat(0.08),
              focusedColor: AppColors.primary.withOpacityCompat(0.3),
              suffixIcon: Obx(() {
                if (ctrl.searchText.value.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    ctrl.searchTec.clear();
                    ctrl.searchText.value = '';
                    ctrl.suggestions.clear();
                    ctrl.isFieldFocused.value = false;
                    ctrl.searchFocusNode.unfocus();
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.white.withOpacityCompat(0.3),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showFilterSheet(context, ctrl),
            child: Obx(() {
              final isActive =
                  ctrl.selectedSource.value != null || ctrl.selectedSort.value != SortOption.newest;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary.withOpacityCompat(0.15) : AppColors.d300,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary.withOpacityCompat(0.5)
                        : AppColors.white.withOpacityCompat(0.08),
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: isActive ? AppColors.primary : AppColors.white.withOpacityCompat(0.5),
                  size: 20,
                ),
              );
            }),
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

          return SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
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
                            label: cat.chilrenCount != null
                                ? '${cat.name ?? ''} (${cat.chilrenCount})'
                                : (cat.name ?? ''),
                            selected: ctrl.selectedCategoryId.value == cat.id,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
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

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: ctrl.searchResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => LinkListItem(index: i, item: ctrl.searchResults[i]),
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
// ─── Suggestion / History panel ──────────────────────────────────────────────

class _SuggestionPanel extends StatelessWidget {
  final SearchLinkController ctrl;
  const _SuggestionPanel({required this.ctrl});
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final query = ctrl.searchText.value.trim();
      final hasQuery = query.isNotEmpty;
      if (!hasQuery && ctrl.searchHistory.isEmpty) {
        // Nothing to show
        return const SizedBox.shrink();
      }

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (!hasQuery) ...[
            // ── Recent searches ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWidget(
                  text: 'Recent searches'.tr,
                  size: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white.withOpacityCompat(0.5),
                ),
                GestureDetector(
                  onTap: ctrl.clearAllHistory,
                  child: TextWidget(text: 'Clear all'.tr, size: 13, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...ctrl.searchHistory.map(
              (item) => _HistoryTile(
                query: item,
                onTap: () => ctrl.applyQuery(item),
                onRemove: () => ctrl.removeFromHistory(item),
              ),
            ),
          ] else ...[
            // ── Autocomplete suggestions ─────────────────────────────────────
            if (ctrl.suggestions.isNotEmpty) ...[
              TextWidget(
                text: 'Suggestions'.tr,
                size: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.white.withOpacityCompat(0.5),
              ),
              const SizedBox(height: 10),
              ...ctrl.suggestions.map(
                (item) =>
                    _SuggestionTile(text: item, query: query, onTap: () => ctrl.applyQuery(item)),
              ),
            ],
          ],
        ],
      );
    });
  }
}

class _HistoryTile extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _HistoryTile({required this.query, required this.onTap, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Icons.history_rounded, size: 18, color: AppColors.white.withOpacityCompat(0.4)),
            const SizedBox(width: 12),
            Expanded(
              child: TextWidget(
                text: query,
                size: 14,
                color: AppColors.white.withOpacityCompat(0.8),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.white.withOpacityCompat(0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String text;
  final String query;
  final VoidCallback onTap;

  const _SuggestionTile({required this.text, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Highlight the matching portion
    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    final idx = lower.indexOf(qLower);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 18, color: AppColors.white.withOpacityCompat(0.4)),
            const SizedBox(width: 12),
            Expanded(
              child: idx >= 0
                  ? RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.white.withOpacityCompat(0.8),
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          if (idx > 0) TextSpan(text: text.substring(0, idx)),
                          TextSpan(
                            text: text.substring(idx, idx + query.length),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (idx + query.length < text.length)
                            TextSpan(text: text.substring(idx + query.length)),
                        ],
                      ),
                    )
                  : TextWidget(text: text, size: 14, color: AppColors.white.withOpacityCompat(0.8)),
            ),
            Icon(
              Icons.north_west_rounded,
              size: 14,
              color: AppColors.white.withOpacityCompat(0.25),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Source icon helper ──────────────────────────────────────────────────────

Widget _sourceIcon(String host, {double size = 16}) {
  if (host.contains('tiktok.com')) return AppIcons.icLogoTiktok.show(size: size);
  if (host.contains('youtube.com')) return AppIcons.icLogoYoutube.show(size: size);
  if (host.contains('instagram.com')) return AppIcons.icLogoInstagram.show(size: size);
  if (host.contains('facebook.com')) return AppIcons.icLogoFacebook.show(size: size);
  if (host.contains('x.com')) return AppIcons.icLogoTwitter.show(size: size);
  if (host.contains('google.com')) return AppIcons.icLogoGoogle.show(size: size);
  return Icon(Icons.language_rounded, size: size, color: AppColors.white.withOpacityCompat(0.6));
}
// ─── Filter bottom sheet ──────────────────────────────────────────────────────

void _showFilterSheet(BuildContext context, SearchLinkController ctrl) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg500,
    isScrollControlled: true,
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

            // ─ Date range section ────────────────────────────────────────────
            _DateRangeSection(ctrl: ctrl),

            // ─ Source section ─────────────────────────────────────────────────
            Obx(() {
              final sources = ctrl.topSources;
              if (sources.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const TextWidget(
                    text: 'Top sources',
                    color: AppColors.white,
                    size: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sources.map((s) {
                      final selected = ctrl.selectedSource.value == s.host;
                      return GestureDetector(
                        onTap: () {
                          ctrl.selectSource(selected ? null : s.host);
                          Get.back();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary.withOpacityCompat(0.15)
                                : AppColors.white.withOpacityCompat(0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary.withOpacityCompat(0.5)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _sourceIcon(s.host, size: 14),
                              const SizedBox(width: 6),
                              TextWidget(
                                text: s.label,
                                color: selected
                                    ? AppColors.white
                                    : AppColors.white.withOpacityCompat(0.75),
                                size: 13,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.white.withOpacityCompat(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextWidget(
                                  text: '${s.count}',
                                  color: AppColors.white,
                                  size: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            }),

            // Reset button
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                ctrl.selectSort(SortOption.newest);
                ctrl.selectCategory(null);
                ctrl.selectSource(null);
                ctrl.selectDateRange(null, null);
                Navigator.of(context).pop();
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

// ─── Date range section widget ────────────────────────────────────────────────

class _DateRangeSection extends StatelessWidget {
  final SearchLinkController ctrl;
  const _DateRangeSection({required this.ctrl});

  String _fmt(DateTime? d) {
    if (d == null) return 'Any';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickFrom(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ctrl.dateFrom.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: ctrl.dateTo.value ?? DateTime.now(),
      builder: _darkTheme,
    );
    if (picked != null) ctrl.selectDateRange(picked, ctrl.dateTo.value);
  }

  Future<void> _pickTo(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ctrl.dateTo.value ?? DateTime.now(),
      firstDate: ctrl.dateFrom.value ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: _darkTheme,
    );
    if (picked != null) ctrl.selectDateRange(ctrl.dateFrom.value, picked);
  }

  Widget _darkTheme(BuildContext ctx, Widget? child) => Theme(
    data: ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        surface: AppColors.bg500,
        onSurface: AppColors.white,
      ),
    ),
    child: child!,
  );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final from = ctrl.dateFrom.value;
      final to = ctrl.dateTo.value;
      final hasDate = from != null || to != null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              const TextWidget(
                text: 'Saved date',
                color: AppColors.white,
                size: 16,
                fontWeight: FontWeight.w600,
              ),
              if (hasDate) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => ctrl.selectDateRange(null, null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacityCompat(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const TextWidget(
                      text: 'Clear',
                      color: AppColors.primary,
                      size: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'From',
                  value: _fmt(from),
                  onTap: () => _pickFrom(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateButton(label: 'To', value: _fmt(to), onTap: () => _pickTo(context)),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSet = value != 'Any';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSet
              ? AppColors.primary.withOpacityCompat(0.12)
              : AppColors.white.withOpacityCompat(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSet
                ? AppColors.primary.withOpacityCompat(0.45)
                : AppColors.white.withOpacityCompat(0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: isSet ? AppColors.primary : AppColors.white.withOpacityCompat(0.4),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: label,
                  size: 11,
                  color: AppColors.white.withOpacityCompat(0.4),
                  fontWeight: FontWeight.w400,
                ),
                TextWidget(
                  text: value,
                  size: 13,
                  color: isSet ? AppColors.white : AppColors.white.withOpacityCompat(0.55),
                  fontWeight: isSet ? FontWeight.w600 : FontWeight.w400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
