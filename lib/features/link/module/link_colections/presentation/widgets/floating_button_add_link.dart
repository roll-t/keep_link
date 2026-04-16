import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Để dùng HapticFeedback
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/link/module/link_add/presentation/page/add_link_page.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/link_collection_controller.dart';
import 'package:keep_link/features/link/module/link_search/presentation/page/search_link_page.dart';

class FloatingButtonAddLink extends StatelessWidget {
  const FloatingButtonAddLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacityCompat(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomLeft: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacityCompat(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(-4, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomLeft: Radius.circular(32),
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildItem(
                  icon: AppVectors.icSearch.path,
                  label: "Tìm kiếm",
                  onTap: () {
                    Get.toNamed(SearchLinkPage.routeName);
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 24,
                    width: 0.8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.t100.withOpacityCompat(0.4),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                _buildItem(
                  icon: AppVectors.icAddLink.path,
                  label: "Thêm link",
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Get.toNamed(AddLinkPage.routeName)?.then((success) {
                      if (success is bool && success) {
                        Get.find<LinkCollectionController>().onRefreshData();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem({required String icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Utils.showIconsSvg(icon, size: 20, color: AppColors.t100),
            const SizedBox(height: 4),
            TextWidget(text: label, textStyle: AppTextStyle.bold12, color: AppColors.t100),
          ],
        ),
      ),
    );
  }
}
