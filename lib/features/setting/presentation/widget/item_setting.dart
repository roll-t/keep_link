import 'package:flutter/material.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';

class ItemSetting extends StatelessWidget {
  final VoidCallback onTap;
  final Widget? leadingIcon;
  final Widget? subfix;
  final String title;
  const ItemSetting({
    super.key,
    required this.title,
    required this.onTap,
    this.leadingIcon,
    this.subfix,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: AppColors.d300),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 12,
              children: [
                if (leadingIcon != null) leadingIcon!,
                TextWidget(text: title, color: AppColors.t200, textStyle: AppTextStyle.semiBold18),
              ],
            ),
            subfix ?? Icon(Icons.arrow_forward_ios_rounded, color: AppColors.t200),
          ],
        ),
      ),
    );
  }
}
