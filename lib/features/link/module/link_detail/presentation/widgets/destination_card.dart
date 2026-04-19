import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/link_detail_controller.dart';

class DestinationCard extends GetView<LinkDetailController> {
  const DestinationCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget(
              text: "Original Destination".tr,
              textStyle: AppTextStyle.bold12,
              color: Colors.grey,
            ),

            GestureDetector(
              onTap: controller.openInApp,
              child: Row(
                children: [
                  const Icon(Icons.open_in_new, color: AppColors.white, size: 16),
                  const SizedBox(width: 8),
                  TextWidget(
                    text: "Open in App".tr,
                    textStyle: AppTextStyle.semiBold12,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF916BFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.link, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextWidget(
                text: controller.url,
                textStyle: AppTextStyle.regular14,
                color: Colors.blue.shade200,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: controller.copyUrl,
              child: const Icon(Icons.copy, color: Colors.white70, size: 20),
            ),
          ],
        ),
      ],
    ),
  );
}
