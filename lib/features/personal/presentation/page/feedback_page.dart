import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/presentation/widgets/text_field/simple_input_textfield.dart';
import 'package:keep_link/features/personal/presentation/controller/feedback_controller.dart';

class FeedbackPage extends GetView<FeedbackController> {
  static const routeName = '/FeedbackPage';

  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg700,
      appBar: CustomAppBar(title: controller.title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Segmented Tab Selector ──────────────────────────────────
              _buildTypeSelector(),
              const SizedBox(height: 16),

              // ── Sign-in warning if not authenticated ────────────────────
              if (!controller.isSignedIn) ...[
                _buildSignInWarning(),
                const SizedBox(height: 16),
              ],

              // ── Hint Description ─────────────────────────────────────────
              Obx(
                () => TextWidget(
                  text: controller.hint,
                  color: AppColors.onSurfaceVariant,
                  size: 14,
                ),
              ),
              const SizedBox(height: 14),

              // ── Text Input ──────────────────────────────────────────────
              Obx(
                () => SimpleInputTextField(
                  controller: controller.messageController,
                  height: 200,
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
              ),
              const SizedBox(height: 20),

              // ── Submit Button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
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
                    label: Text(
                      controller.isLoading.value ? 'Sending...'.tr : 'Send'.tr,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Footer Note ─────────────────────────────────────────────
              Center(
                child: TextWidget(
                  text: 'Your feedback helps us improve Linkeep.'.tr,
                  color: AppColors.outlineVariant,
                  size: 12,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.d500,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.d200),
      ),
      child: Obx(() {
        final current = controller.selectedType.value;
        return Row(
          children: [
            Expanded(
              child: _TabButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Feedback'.tr,
                isSelected: current == FeedbackType.feedback,
                onTap: () => controller.setType(FeedbackType.feedback),
              ),
            ),
            Expanded(
              child: _TabButton(
                icon: Icons.bug_report_outlined,
                label: 'Bug Report'.tr,
                isSelected: current == FeedbackType.bugReport,
                onTap: () => controller.setType(FeedbackType.bugReport),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSignInWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextWidget(
              text: 'Please sign in to send feedback.'.tr,
              color: Colors.orange,
              size: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
