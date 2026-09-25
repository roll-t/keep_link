import 'package:flutter/material.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';

/// Item configuration for [AppSegmentedTab].
class AppSegmentTabItem {
  final String label;
  final String? semanticLabel;
  final Widget? icon;
  final int? count;

  const AppSegmentTabItem({
    required this.label,
    this.semanticLabel,
    this.icon,
    this.count,
  });
}

/// A modern, reusable segmented pill tab bar conforming to the design tokens in `lib/core`.
class AppSegmentedTab extends StatelessWidget {
  const AppSegmentedTab({
    super.key,
    required this.selectedIndex,
    required this.tabs,
    required this.onChanged,
    this.height = 42,
    this.backgroundColor = AppColors.surfaceContainerHighest,
    this.selectedColor = AppColors.primary,
    this.selectedGradient,
    this.borderColor,
    this.borderRadius = 12,
    this.padding = 4,
    this.animationDuration = const Duration(milliseconds: 280),
    this.animationCurve = Curves.easeOutCubic,
  }) : assert(tabs.length > 0);

  final int selectedIndex;
  final List<AppSegmentTabItem> tabs;
  final ValueChanged<int> onChanged;
  final double height;
  final Color backgroundColor;
  final Color selectedColor;
  final Gradient? selectedGradient;
  final Color? borderColor;
  final double borderRadius;
  final double padding;
  final Duration animationDuration;
  final Curve animationCurve;

  @override
  Widget build(BuildContext context) {
    final safeSelectedIndex = selectedIndex.clamp(0, tabs.length - 1);

    return Container(
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / tabs.length;

          return Stack(
            alignment: Alignment.center,
            children: [
              AnimatedPositioned(
                duration: animationDuration,
                curve: animationCurve,
                top: 0,
                bottom: 0,
                left: segmentWidth * safeSelectedIndex,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: selectedGradient == null ? selectedColor : null,
                    gradient: selectedGradient,
                    borderRadius: BorderRadius.circular(
                      (borderRadius - padding).clamp(0, borderRadius),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: selectedColor.withOpacityCompat(.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    final isSelected = safeSelectedIndex == index;
                    final tab = tabs[index];

                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: tab.semanticLabel ?? tab.label,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(index),
                          child: Center(
                            child: TweenAnimationBuilder<double>(
                              duration: animationDuration,
                              curve: animationCurve,
                              tween: Tween(end: isSelected ? 1 : 0),
                              builder: (context, progress, _) {
                                final foreground = Color.lerp(
                                  AppColors.n70,
                                  AppColors.white,
                                  progress,
                                )!;

                                return Transform.scale(
                                  scale: .94 + (.06 * progress),
                                  child: IconTheme(
                                    data: IconThemeData(
                                      size: 16,
                                      color: foreground,
                                    ),
                                    child: _buildTabContent(
                                      tab: tab,
                                      foreground: foreground,
                                      progress: progress,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabContent({
    required AppSegmentTabItem tab,
    required Color foreground,
    required double progress,
  }) {
    final badgeBackground = Color.lerp(
      AppColors.surface.withOpacityCompat(.6),
      AppColors.white.withOpacityCompat(.22),
      progress,
    )!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (tab.icon != null) tab.icon!,
        if (tab.icon != null && tab.label.isNotEmpty) const SizedBox(width: 6),
        if (tab.label.isNotEmpty)
          TextWidget(
            text: tab.label,
            color: foreground,
            textStyle: progress >= .5
                ? AppTextStyle.semiBold14
                : AppTextStyle.medium14,
          ),
        if (tab.count != null && tab.count! > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextWidget(
              text: '${tab.count}',
              color: foreground,
              textStyle: AppTextStyle.bold10,
            ),
          ),
        ],
      ],
    );
  }
}
