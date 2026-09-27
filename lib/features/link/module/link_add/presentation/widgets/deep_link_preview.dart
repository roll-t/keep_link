import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/widgets/image/cache_image.dart';
import 'package:keep_link/core/presentation/widgets/shimmer/app_shimmer.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/state/controllers/deep_link_controller.dart';

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
          return const SizedBox.shrink();
        }

        return _buildPreview(
          title: data.title,
          description: data.description,
          imageUrl: data.imageUrl,
        );
      },
    );
  }

  Widget _buildLoading() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.navigationSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: AppShimmer(
        child: Row(
          children: [
            Container(
              width: 110,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonLine(width: double.infinity, height: 14),
                    const SizedBox(height: 10),
                    _skeletonLine(width: 170, height: 10),
                    const SizedBox(height: 7),
                    _skeletonLine(width: 110, height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPreview({
    required String title,
    required String description,
    required String imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.navigationSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageUrl.isNotEmpty) _buildImage(imageUrl),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextWidget(
                    text: title.isNotEmpty ? title : "KeepLink Preview",
                    maxLines: 1,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  TextWidget(
                    text: description,
                    maxLines: 2,
                    color: AppColors.t200,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return CacheImageWidget(
      imageUrl: imageUrl,
      width: 110,
      height: 90,
      fit: BoxFit.cover,
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
    );
  }
}
