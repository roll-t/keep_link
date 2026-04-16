import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/link_detail_controller.dart';

class LinkActionButtons extends GetView<LinkDetailController> {
  const LinkActionButtons({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(child: _OpenButton()),
          const SizedBox(width: 16),
          Expanded(child: _EditButton()),
        ],
      ),
      const SizedBox(height: 24),
      _DeleteButton(),
    ],
  );
}

class _OpenButton extends GetView<LinkDetailController> {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: controller.openInApp,
    child: Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF916BFF),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.open_in_new, color: Colors.black87, size: 18),
          const SizedBox(width: 8),
          TextWidget(
            text: "Open in App",
            textStyle: AppTextStyle.semiBold16,
            color: Colors.black87,
          ),
        ],
      ),
    ),
  );
}

class _EditButton extends GetView<LinkDetailController> {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: controller.goToEdit,
    child: Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          TextWidget(text: "Edit Entry", textStyle: AppTextStyle.semiBold16, color: Colors.white),
        ],
      ),
    ),
  );
}

class _DeleteButton extends GetView<LinkDetailController> {
  @override
  Widget build(BuildContext context) => Center(
    child: GestureDetector(
      onTap: controller.deleteLink,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
            const SizedBox(width: 8),
            TextWidget(
              text: "Remove from Library",
              textStyle: AppTextStyle.semiBold14,
              color: AppColors.red,
            ),
          ],
        ),
      ),
    ),
  );
}
