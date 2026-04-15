import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/link/application/controller/link_collection_controller.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/presentation/link_colections/widgets/link_item.dart';

class ListLinkCollection extends GetView<LinkCollectionController> {
  const ListLinkCollection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.listLink.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final listLink = controller.listLink;
      if (listLink.isEmpty) {
        return _buildEmptyState();
      }

      return _buildLinkGrid(listLink);
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppVectors.icEmpty.show(color: AppColors.d100, size: Get.width * .3),
          const SizedBox(height: 18),
          const TextWidget(
            text: "Chưa có link nào",
            color: AppColors.t100,
            textStyle: AppTextStyle.medium18,
          ),
          const SizedBox(height: 6),
          const TextWidget(
            text: "Hãy lưu những link bạn yêu thích",
            color: AppColors.t400,
            textStyle: AppTextStyle.medium14,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              controller.onRefreshData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.d100,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [TextWidget(text: "Reload")],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkGrid(List<LinkModel> listLink) {
    return RefreshIndicator(
      onRefresh: controller.onRefreshData,
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              controller: controller.scrollController,
              padding: const EdgeInsets.only(top: 105, bottom: 20, left: 12, right: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: listLink.length,
              itemBuilder: (context, index) => LinkItem(index: index, item: listLink[index]),
            ),
          ),
        ],
      ),
    );
  }
}
