import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/ui/appbar/custom_app_bar.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/ui/text_field/simple_input_textfield.dart';
import 'package:keep_link/features/personal/presentation/controller/feedback_controller.dart';

class FeedbackPage extends GetView<FeedbackController> {
  static const routeName = '/FeedbackPage';

  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg700,
      appBar: CustomAppBar(title: controller.title),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(text: controller.hint, color: AppColors.onSurfaceVariant, size: 14),
            const SizedBox(height: 16),
            SimpleInputTextField(
              controller: controller.messageController,
              height: 210,
              maxLine: 10,
              minLines: 6,
              maxLength: 2000,
              textColor: AppColors.onSurface,
              fontSize: 14,
              backgroundColor: AppColors.d500,
              enableColor: AppColors.d200,
              focusedColor: AppColors.primary,
              radius: 12,
              contentPadding: const EdgeInsets.all(14),
              textAlignVertical: TextAlignVertical.top,
              hintText: controller.inputHint,
              hintStyle: TextStyle(color: AppColors.outlineVariant, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Obx(
                () => ElevatedButton.icon(
                  onPressed: controller.isLoading.value ? null : controller.submit,
                  icon: controller.isLoading.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(controller.actionIcon, size: 18),
                  label: Text(controller.isLoading.value ? 'Sending...'.tr : 'Send'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextWidget(
              text: 'Your feedback helps us improve LinkCapture.'.tr,
              color: AppColors.outlineVariant,
              size: 12,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
