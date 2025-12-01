// deep_link_preview_section.dart (hoặc để cuối file hiện tại)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/utils/controller/deep_link_controller.dart';

class DeepLinkPreview extends StatelessWidget {
  const DeepLinkPreview({super.key});

  @override
  Widget build(BuildContext context) {
    // Nếu không phải mở từ share thì ẩn luôn để đỡ tốn tài nguyên render
    if (!DeepLinkService.isOpenedFromShare) return const SizedBox.shrink();

    return GetBuilder<DeepLinkController>(
      id: "EXTRA_LINK_ID",
      builder: (controller) {
        if (controller.isLoading.value) {
          return _buildLoading();
        }

        final data = controller.metaData.value;
        if (data == null) {
          return const TextWidget(text: "⚠ Không có dữ liệu deep link", color: AppColors.red);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8.0,
          children: [
            if (data.url.isNotEmpty) TextWidget(text: data.url, color: AppColors.blue, maxLines: 1),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary, width: 1.0),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data.imageUrl.isNotEmpty) _buildImage(data.imageUrl),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
                        child: Column(
                          spacing: 4.0,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (data.title.isNotEmpty)
                              TextWidget(
                                text: data.title,
                                size: 12,
                                maxLines: 2,
                                fontWeight: FontWeight.w600,
                              ),
                            TextWidget(
                              text: data.description,
                              fontWeight: FontWeight.w400,
                              size: 12,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
    );
  }

  Widget _buildImage(String imageUrl) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)), // -1px border
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 90,
        height: 70,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.grey.shade200),
        errorWidget: (_, __, ___) =>
            const SizedBox(width: 90, child: Icon(Icons.broken_image, color: Colors.grey)),
      ),
    );
  }
}
