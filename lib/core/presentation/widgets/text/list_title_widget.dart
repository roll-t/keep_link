import 'package:flutter/material.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_extension.dart';

class ListTitleWidget extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isEnabled;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? contentPadding;

  const ListTitleWidget({
    super.key,
    this.icon,
    required this.title,
    required this.subtitle,
    this.isActive = false,
    this.isEnabled = true,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 2,
    ),
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: isEnabled ? onTap : null,
      contentPadding: contentPadding,
      minLeadingWidth: 32,
      leading: icon == null
          ? null
          : AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withOpacityCompat(0.18)
                    : AppColors.white.withOpacityCompat(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 17,
                color: isActive
                    ? AppColors.primaryContainer
                    : AppColors.onSurfaceVariant,
              ),
            ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          title.textSemiBold14(maxLines: 1),
          const SizedBox(height: 2),
          subtitle.textRegular10(maxLines: 1),
        ],
      ),
      trailing: trailing,
    );
  }
}
