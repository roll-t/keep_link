import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final AppTextStyleModel? titleStyle;

  const CustomAppBar({
    super.key,
    this.titleWidget,
    this.title = "",
    this.showBackButton = true,
    this.onBack,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: backgroundColor,
      centerTitle: centerTitle,
      leading: showBackButton
          ? GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onBack ?? () => Get.back(),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.t200),
            )
          : null,
      automaticallyImplyLeading: false,
      title:
          titleWidget ?? TextWidget(text: title, textStyle: titleStyle ?? AppTextStyle.semiBold20),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
