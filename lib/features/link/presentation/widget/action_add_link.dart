import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/link/application/controller/link_collection_controller.dart';
import 'package:keep_link/features/link/presentation/page/add_link_page.dart';

class ActionAddLink extends StatelessWidget {
  const ActionAddLink({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        Get.toNamed(AddLinkPage.routeName)?.then((success) {
          if (success is bool && success) {
            Get.find<LinkCollectionController>().onRefreshData();
          }
        });
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1000),
          color: AppColors.primary,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Transform.rotate(angle: 3.1415926535 / 2, child: AppVectors.icAddLink.show(size: 15)),
            TextWidget(text: "Thêm link", textStyle: AppTextStyle.bold16, color: AppColors.t100),
          ],
        ),
      ),
    );
  }
}
