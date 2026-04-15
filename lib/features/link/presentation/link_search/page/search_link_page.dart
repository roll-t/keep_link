import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/ui/appbar/custom_app_bar.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/ui/text_field/simple_input_textfield.dart';
import 'package:keep_link/features/link/application/controller/search_link_controller.dart';
import 'package:keep_link/features/link/presentation/link_colections/widgets/link_item.dart';

class SearchLinkPage extends GetView<SearchLinkController> {
  static String routeName = "/SearchLinkPage";
  const SearchLinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: SimpleInputTextField(
          controller: controller.searchTec.value,
          hintText: "Nhập tên link hoặc ghi chú...",
          radius: 100,
          onChanged: (value) {},
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, color: AppColors.t400),
            onPressed: () => controller.searchTec.value.clear(),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.searchText.value.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppVectors.icSearchFile.show(color: AppColors.d100, size: Get.width * .3),
                const SizedBox(height: 20),
                const TextWidget(
                  textAlign: TextAlign.center,
                  text: "Hãy nhập từ khóa để\ntìm kiếm",
                  color: AppColors.t300,
                  textStyle: AppTextStyle.medium18,
                ),
              ],
            ),
          );
        }

        if (controller.searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppVectors.icSearchNotFound.show(color: AppColors.d100, size: Get.width * .3),
                const SizedBox(height: 20),
                const TextWidget(
                  textAlign: TextAlign.center,
                  text: "Không tìm thấy kết quả phù hợp",
                  color: AppColors.t300,
                  textStyle: AppTextStyle.medium18,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: controller.searchResults.length,
          itemBuilder: (context, index) {
            return LinkItem(index: index, item: controller.searchResults[index]);
          },
        );
      }),
    );
  }
}
