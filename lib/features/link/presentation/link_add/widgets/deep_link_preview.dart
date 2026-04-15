import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/utils/controller/deep_link_controller.dart';

class DeepLinkPreview extends StatelessWidget {
  const DeepLinkPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DeepLinkController>(
      id: "EXTRA_LINK_ID",
      builder: (controller) {
        if (controller.isLoading.value) {
          return _buildLoading();
        }
        final data = controller.metaData.value;
        if (data == null) {
          return SizedBox.shrink();
        }
        if (data.imageUrl == "" && data.title == "") {
          return SizedBox.shrink();
        }

        return Container(
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
                      spacing: 8.0,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (data.title.isNotEmpty)
                          TextWidget(
                            text: data.title,
                            size: 14,
                            maxLines: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        TextWidget(
                          text: data.description,
                          fontWeight: FontWeight.w400,
                          size: 14,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 92,
      decoration: BoxDecoration(color: AppColors.d200, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
              color: AppColors.d100,
            ),
            width: 110,
            height: 90,
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 110,
        height: 90,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.d200),
        errorWidget: (_, __, ___) =>
            const SizedBox(width: 110, child: Icon(Icons.broken_image, color: AppColors.d100)),
      ),
    );
  }
}
