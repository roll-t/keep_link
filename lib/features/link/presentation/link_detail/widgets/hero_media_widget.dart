import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/core/ui/image/cache_image.dart';
import 'package:keep_link/core/ui/image/full_screen_image_page.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/link/application/controller/link_detail_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HeroMediaWidget extends GetView<LinkDetailController> {
  const HeroMediaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (controller.imageUrl.isEmpty) return const SizedBox.shrink();

    return Obx(
      () => controller.isPlayingVideo.value
          ? _WebViewPlayer(ctrl: controller.webViewController!)
          : _ThumbnailWithPlay(),
    );
  }
}

class _WebViewPlayer extends StatelessWidget {
  final WebViewController ctrl;
  const _WebViewPlayer({required this.ctrl});

  @override
  Widget build(BuildContext context) => Container(
    height: Get.width * .8,
    width: double.infinity,
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
    child: WebViewWidget(controller: ctrl),
  );
}

class _ThumbnailWithPlay extends GetView<LinkDetailController> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => FullScreenImagePage(imageUrl: controller.imageUrl)),
      child: Hero(
        tag: controller.imageUrl,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CacheImageWidget(
              borderRadius: BorderRadius.circular(16),
              imageUrl: controller.imageUrl,
              height: Get.width * .8,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            _PlayButton(onTap: controller.playVideo),
            const _SavedBadge(),
          ],
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacityCompat(0.6),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
    ),
  );
}

class _SavedBadge extends StatelessWidget {
  const _SavedBadge();

  @override
  Widget build(BuildContext context) => Positioned(
    top: 12,
    right: 12,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacityCompat(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bookmark, color: AppColors.primary, size: 14),
          const SizedBox(width: 4),
          TextWidget(
            text: "Saved recently",
            textStyle: AppTextStyle.regular12,
            color: AppColors.white,
          ),
        ],
      ),
    ),
  );
}
