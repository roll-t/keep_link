import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/core/ui/appbar/custom_app_bar.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/security/application/controller/security_method_controller.dart';

class SecurityMethodPage extends GetView<SecurityMethodController> {
  static String routeName = "/SecurityMethodPage";

  const SecurityMethodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Phương thức bảo mật"),
      body: Obx(() {
        final isAppSecOn = controller.isAppSecurityEnabled.value;
        final isCatSecOn = controller.isCategorySecurityEnabled.value;
        final isFingerOn = controller.isFingerprintEnabled.value;
        final isPinActive = isAppSecOn || isCatSecOn;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ==============================
                // PHẦN 1: CÁC SWITCH CÀI ĐẶT
                // ==============================
                Column(
                  children: [
                    _buildSwitchItem(
                      title: "Bảo mật ứng dụng",
                      value: isAppSecOn,
                      onChanged: (_) => controller.toggleAppSecurity(),
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchItem(
                      title: "Bảo mật danh mục",
                      value: isCatSecOn,
                      isEnabled: true,
                      onChanged: (_) => controller.toggleCategorySecurity(),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ==============================
                // PHẦN 2: CÁC NÚT TÙY CHỌN LỚN
                // ==============================
                SizedBox(
                  height: Get.height * .6,
                  child: Column(
                    children: [
                      // ----- Nút PIN -----
                      Expanded(
                        child: _buildBigOptionCard(
                          title: "Mã PIN",
                          iconVector: AppVectors.icPin.path,
                          isEnabled: isPinActive,
                          isActive: isPinActive,
                          onTap: () => controller.changePin(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ----- Nút Vân tay -----
                      Expanded(
                        child: _buildBigOptionCard(
                          title: "Vân tay",
                          iconVector: AppVectors.icFinger.path,
                          isEnabled: isAppSecOn,
                          isActive: isFingerOn,
                          onTap: () => controller.toggleFingerprint(),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Get.mediaQuery.padding.bottom),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Widget con: Dòng Switch bật tắt
  Widget _buildSwitchItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isEnabled = true,
  }) {
    return Opacity(
      opacity: isEnabled ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.d300),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget(text: title, textStyle: AppTextStyle.semiBold18),
            Switch(
              value: value,
              onChanged: isEnabled ? onChanged : null,
              activeThumbColor: AppColors.primary,
              inactiveTrackColor: Colors.grey.withOpacityCompat(0.3),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget con: Thẻ tùy chọn lớn (PIN / Vân tay)
  Widget _buildBigOptionCard({
    required String title,
    required String iconVector,
    required bool isEnabled,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: isEnabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !isEnabled,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.d300,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                width: isActive ? 2 : 0,
                color: isActive ? AppColors.primary : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Utils.showIconsSvg(
                  iconVector,
                  width: Get.width * 0.25,
                  color: isActive ? AppColors.primary : AppColors.t200,
                ),
                const SizedBox(height: 12),
                TextWidget(
                  text: title,
                  textStyle: AppTextStyle.bold36,
                  color: isActive ? AppColors.primary : AppColors.t200,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
