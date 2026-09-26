import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_icons.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/background/app_animated_background.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/presentation/widgets/text_field/simple_input_textfield.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/widgets/link_item.dart';
import 'package:keep_link/features/link/module/link_search/presentation/controller/search_link_controller.dart';

class SearchLinkPage extends GetView<SearchLinkController> {
  static String routeName = '/SearchLinkPage';
  const SearchLinkPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: AppAnimatedBackground(intensity: .58)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
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
                        const SizedBox(height: 12),
                        Expanded(child: _ResultBody(ctrl: controller)),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
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
          InkWell(
            onTap: () => Get.back(),
            child: const SizedBox.square(
              dimension: 42,
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.onSurface),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SimpleInputTextField(
              height: 38,
              fontSize: 14,
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 4),
                child: Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: AppColors.primaryContainer.withOpacityCompat(.62),
                ),
              ),
              radius: 1000,
              hintText: 'Search links'.tr,
              controller: ctrl.searchTec,
              focusNode: ctrl.searchFocusNode,
              backgroundColor: AppColors.navigationSurface,
              enableColor: AppColors.white.withOpacityCompat(.1),
              focusedColor: AppColors.primaryDim,
              isShowBorder: false,
              textInputAction: TextInputAction.search,
              onCompleted: (text) {
                if (text.trim().isNotEmpty) ctrl.applyQuery(text.trim());
              },
              suffixIcon: Obx(() {
                if (ctrl.searchText.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: ctrl.clearSearch,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.white.withOpacityCompat(0.3),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showFilterSheet(context, ctrl),
            child: Obx(() {
              final isActive = ctrl.hasActiveFilters;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 30,
                    height: 30,
                    child: Icon(
                      Icons.tune_rounded,
                      color: isActive
                          ? AppColors.primaryDim
                          : AppColors.primaryContainer.withOpacityCompat(.7),
                      size: 20,
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      right: -2,
                      top: -3,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.background, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: TextWidget(
                          text: '${ctrl.activeFilterCount}',
                          textStyle: AppTextStyle.regular8,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                ],
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
          final selectedId = ctrl.selectedCategoryId.value;
          return SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              controller: ctrl.categoryScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'All'.tr,
                    selected: selectedId == null,
                    onTap: () => ctrl.selectCategory(null),
                  ),
                  ...cats.map((cat) {
                    final label = cat.chilrenCount != null
                        ? '${cat.name ?? ''} (${cat.chilrenCount})'
                        : (cat.name ?? '');
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _CategoryChip(
                        label: label,
                        selected: selectedId == cat.id,
                        onTap: () => ctrl.selectCategory(cat.id),
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

class _CategoryChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onTap();

    // Tự động cuộn nhẹ nhàng VÀO VÙNG NHÌN THẤY chỉ khi chip đang bị khuất/nằm sát mép màn hình.
    // Nếu chip đã hoàn toàn nằm gọn trong màn hình, giữ nguyên vị trí để không bị xê dịch dưới tay.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeScrollIntoView();
    });
  }

  void _maybeScrollIntoView() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;

    final scrollRenderBox = scrollable.context.findRenderObject() as RenderBox?;
    if (scrollRenderBox == null) return;

    final itemOffset = renderBox.localToGlobal(Offset.zero, ancestor: scrollRenderBox);
    final itemLeft = itemOffset.dx;
    final itemRight = itemLeft + renderBox.size.width;
    final viewportWidth = scrollRenderBox.size.width;

    const margin = 16.0;
    // Đã nằm an toàn trong khung nhìn -> không cần scroll, giữ trải nghiệm mượt mà tức thì
    if (itemLeft >= margin && itemRight <= viewportWidth - margin) {
      return;
    }

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: itemLeft < margin ? 0.05 : 0.95,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primaryDim : AppColors.white.withOpacityCompat(.10),
              width: 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacityCompat(0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Nền mặc định (unselected)
                Container(color: AppColors.navigationSurface),
                // Nền gradient chuyển đổi mượt bằng GPU opacity layer, không bị snap lerp
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: selected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primaryBright, AppColors.primary],
                        ),
                      ),
                    ),
                  ),
                ),
                // Text nhãn với animation màu sắc và độ dày chữ mượt mà
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppColors.white : AppColors.white.withOpacityCompat(0.60),
                    ),
                    child: Text(widget.label),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      Widget body;
      // Loading
      if (ctrl.isLoading.value) {
        body = const Center(
          key: ValueKey('loading'),
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
        );
      } else if (ctrl.searchResults.isEmpty && ctrl.searchText.value.isNotEmpty) {
        body = const _EmptyState(
          key: ValueKey('empty_search'),
          icon: AppVectors.icSearchNotFound,
          message: 'No matching results found',
        );
      } else if (ctrl.searchResults.isEmpty) {
        body = const _EmptyState(
          key: ValueKey('empty_db'),
          icon: AppVectors.icSearchFile,
          message: 'No links yet\nAdd your first link!',
        );
      } else {
        body = ListView.separated(
          key: const ValueKey('results_list'),
          padding: const EdgeInsets.only(top: 4, bottom: 24),
          itemCount: ctrl.searchResults.length,
          separatorBuilder: (_, __) => Divider(
            height: .5,
            thickness: 0.8,
            indent: 0,
            endIndent: 0,
            color: AppColors.white.withOpacityCompat(0.10),
          ),
          itemBuilder: (_, i) => LinkListItem(index: i, item: ctrl.searchResults[i]),
        );
      }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: body,
      );
    });
  }
}

class _EmptyState extends StatelessWidget {
  final dynamic icon;
  final String message;
  const _EmptyState({super.key, required this.icon, required this.message});

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
  if (host.contains('tiktok.com')) {
    return AppIcons.icLogoTiktok.show(size: size);
  }
  if (host.contains('youtube.com')) {
    return AppIcons.icLogoYoutube.show(size: size);
  }
  if (host.contains('instagram.com')) {
    return AppIcons.icLogoInstagram.show(size: size);
  }
  if (host.contains('facebook.com')) {
    return AppIcons.icLogoFacebook.show(size: size);
  }
  if (host.contains('x.com')) {
    return AppIcons.icLogoTwitter.show(size: size);
  }
  if (host.contains('google.com')) {
    return AppIcons.icLogoGoogle.show(size: size);
  }
  return Icon(Icons.language_rounded, size: size, color: AppColors.white.withOpacityCompat(0.6));
}
// ─── Filter bottom sheet ──────────────────────────────────────────────────────

void _showFilterSheet(BuildContext context, SearchLinkController ctrl) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.modalSurface,
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacityCompat(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                const TextWidget(
                  text: 'Filters',
                  color: AppColors.white,
                  size: 19,
                  fontWeight: FontWeight.w700,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.white.withOpacityCompat(0.55),
                    size: 21,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            const TextWidget(
              text: 'Sort by',
              color: AppColors.white,
              size: 16,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 10),

            Obx(
              () => Column(
                children: _sortOptions.map((opt) {
                  final (value, label, icon) = opt;
                  final selected = ctrl.selectedSort.value == value;
                  return GestureDetector(
                    onTap: () => ctrl.selectSort(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacityCompat(0.15)
                            : AppColors.white.withOpacityCompat(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary.withOpacityCompat(0.5)
                              : AppColors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            color: selected
                                ? AppColors.primary
                                : AppColors.white.withOpacityCompat(0.5),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          TextWidget(
                            text: label,
                            color: selected
                                ? AppColors.white
                                : AppColors.white.withOpacityCompat(0.6),
                            size: 14,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          const Spacer(),
                          if (selected)
                            Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 17),
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
                        onTap: () => ctrl.selectSource(selected ? null : s.host),
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
                                  : AppColors.transparent,
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

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: ctrl.resetFilters,
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacityCompat(0.06),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: AppColors.white.withOpacityCompat(0.06)),
                      ),
                      child: const TextWidget(
                        text: 'Reset filters',
                        color: AppColors.n80,
                        size: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacityCompat(0.24),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const TextWidget(
                        text: 'Apply filters',
                        color: AppColors.white,
                        size: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
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
    // "lastDate" here is capped to the already-picked "To" date when it's in
    // the past — showDatePicker asserts initialDate <= lastDate, and
    // defaulting initialDate to DateTime.now() (as before) breaks that as
    // soon as "To" is set to any date earlier than today.
    final lastDate = ctrl.dateTo.value ?? DateTime.now();
    final initialDate = ctrl.dateFrom.value ?? lastDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: DateTime(2020),
      lastDate: lastDate,
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
        surface: AppColors.modalSurface,
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
