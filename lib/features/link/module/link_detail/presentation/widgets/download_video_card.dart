import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/image/cache_image.dart';
import 'package:keep_link/core/presentation/widgets/text/list_title_widget.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/link_detail_controller.dart';

class DownloadVideoCard extends GetView<LinkDetailController> {
  const DownloadVideoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return !controller.canDownloadVideo
        ? const SizedBox.shrink()
        : Obx(() {
            final downloading = controller.isDownloadingVideo.value;
            final downloaded = controller.hasDownloadedVideo;
            final progress = controller.downloadProgress.value;
            final progressLabel = '${(progress * 100).round()}%';
            return Material(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              child: ListTitleWidget(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                onTap: downloading
                    ? controller.cancelVideoDownload
                    : downloaded
                    ? controller.openDownloadedVideo
                    : controller.downloadVideo,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacityCompat(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: downloaded
                      ? CacheImageWidget(
                          imageUrl: controller.imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(8),
                          memCacheWidth: 120,
                          memCacheHeight: 120,
                          errorWidget: const Icon(
                            Icons.play_circle_fill_rounded,
                            color: AppColors.primaryBright,
                            size: 22,
                          ),
                        )
                      : downloading
                      ? SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            value: progress > 0 ? progress : null,
                            strokeWidth: 2.5,
                            color: AppColors.primaryBright,
                          ),
                        )
                      : const Icon(
                          Icons.download_rounded,
                          color: AppColors.primaryBright,
                          size: 22,
                        ),
                ),
                title: downloading
                    ? 'downloading_video'.trParams({'progress': progressLabel})
                    : downloaded
                    ? 'watch_video'.tr
                    : 'download_video'.tr,
                subtitle: downloading
                    ? 'tap_to_cancel_download'.tr
                    : downloaded
                    ? 'video_saved_to_gallery'.tr
                    : 'download_best_available_quality'.tr,
                subtitleMaxLines: 2,
                trailing: !downloaded
                    ? Icon(Icons.arrow_forward_ios, size: 18, color: AppColors.white70)
                    : AppVectors.icPlay.show(color: AppColors.white70, size: 16),
              ),
            );
          });
  }
}
