import 'package:flutter/material.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';

/// Standard header for modal bottom sheets and dialogs.
/// Ensures full-width layout and prevents action buttons from overlapping titles.
class SheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final double height;
  final AppTextStyleModel? titleStyle;
  final AppTextStyleModel? subtitleStyle;
  final Color titleColor;
  final Color subtitleColor;

  const SheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.height = 56.0,
    this.titleStyle,
    this.subtitleStyle,
    this.titleColor = AppColors.white,
    this.subtitleColor = AppColors.n70,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered title + subtitle with safe padding on both sides
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 68),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextWidget(
                  text: title,
                  color: titleColor,
                  textStyle: titleStyle ?? AppTextStyle.bold18,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  TextWidget(
                    text: subtitle!,
                    color: subtitleColor,
                    textStyle: subtitleStyle ?? AppTextStyle.regular12,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
          if (leading != null) Positioned(left: 12, child: leading!),
          if (trailing != null) Positioned(right: 12, child: trailing!),
        ],
      ),
    );
  }
}
