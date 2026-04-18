import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_icons.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/core/ui/image/cache_image.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/page/link_detail.dart';

class LinkItem extends StatelessWidget {
  final int index;
  final LinkModel item;
  const LinkItem({super.key, required this.index, required this.item});

  String _extractHost(String? url) {
    if (url == null || url.isEmpty) return '';
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return '';
    }
  }

  /// Trả về asset icon widget nếu domain khớp, null nếu không có.
  Widget? _resolveAppIcon(String host) {
    if (host.contains('tiktok.com')) return AppIcons.icLogoTiktok.show(size: 12);
    if (host.contains('twitter.com') || host.contains('x.com')) {
      return AppIcons.icLogoTwitter.show(size: 12);
    }
    if (host.contains('instagram.com')) return AppIcons.icLogoInstagram.show(size: 12);
    if (host.contains('facebook.com') || host.contains('fb.com')) {
      return AppIcons.icLogoFacebook.show(size: 12);
    }
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return AppIcons.icLogoYoutube.show(size: 12);
    }
    if (host.contains('google.com')) return AppIcons.icLogoGoogle.show(size: 12);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final meta = item.metaDataModel;
    final host = _extractHost(meta?.url);
    final favicon = meta?.favicon ?? meta?.appleIcon ?? '';
    final appIcon = _resolveAppIcon(host);

    return GestureDetector(
      onTap: () {
        Get.bottomSheet(
          LinkDetailPage(link: item),
          barrierColor: AppColors.black.withOpacityCompat(.8),
          isScrollControlled: true,
          backgroundColor: AppColors.transparent,
        );
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CacheImageWidget(
                borderRadius: BorderRadius.circular(12),
                imageUrl: item.metaDataModel?.imageUrl ?? "/",
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: EdgeInsets.all(12),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.white.withOpacityCompat(.8),
                ),
                child: TextWidget(
                  text: item.name ?? "",
                  textAlign: TextAlign.center,
                  textStyle: AppTextStyle.semiBold14,
                  color: AppColors.t700,
                  maxLines: 5,
                ),
              ),
            ),
            if (host.isNotEmpty)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacityCompat(0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Leading icon: asset > favicon network > globe
                      if (appIcon != null) ...[
                        appIcon,
                        const SizedBox(width: 4),
                      ] else if (favicon.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.network(
                            favicon,
                            width: 12,
                            height: 12,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.language_rounded, size: 12, color: AppColors.n80),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ] else ...[
                        const Icon(Icons.language_rounded, size: 12, color: AppColors.n80),
                        const SizedBox(width: 4),
                      ],
                      TextWidget(
                        text: host,
                        color: AppColors.white,
                        size: 10,
                        fontWeight: FontWeight.w500,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Horizontal list item dùng cho trang search ───────────────────────────────

class LinkListItem extends StatelessWidget {
  final int index;
  final LinkModel item;
  const LinkListItem({super.key, required this.index, required this.item});

  String _extractHost(String? url) {
    if (url == null || url.isEmpty) return '';
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return '';
    }
  }

  Widget? _resolveAppIcon(String host) {
    if (host.contains('tiktok.com')) return AppIcons.icLogoTiktok.show(size: 14);
    if (host.contains('twitter.com') || host.contains('x.com')) {
      return AppIcons.icLogoTwitter.show(size: 14);
    }
    if (host.contains('instagram.com')) return AppIcons.icLogoInstagram.show(size: 14);
    if (host.contains('facebook.com') || host.contains('fb.com')) {
      return AppIcons.icLogoFacebook.show(size: 14);
    }
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return AppIcons.icLogoYoutube.show(size: 14);
    }
    if (host.contains('google.com')) return AppIcons.icLogoGoogle.show(size: 14);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final meta = item.metaDataModel;
    final host = _extractHost(meta?.url);
    final favicon = meta?.favicon ?? meta?.appleIcon ?? '';
    final appIcon = _resolveAppIcon(host);
    final imageUrl = meta?.imageUrl ?? '';
    final description = meta?.description ?? '';

    return GestureDetector(
      onTap: () {
        Get.bottomSheet(
          LinkDetailPage(link: item),
          barrierColor: AppColors.black.withOpacityCompat(.8),
          isScrollControlled: true,
          backgroundColor: AppColors.transparent,
        );
      },
      child: Container(
        height: 104,
        decoration: BoxDecoration(
          color: AppColors.d300,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.white.withOpacityCompat(0.06)),
        ),
        child: Row(
          children: [
            // Thumbnail bên trái
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              child: imageUrl.isNotEmpty
                  ? CacheImageWidget(imageUrl: imageUrl, width: 110, height: 110, fit: BoxFit.cover)
                  : Container(
                      width: 110,
                      height: 110,
                      color: AppColors.surface,
                      child: const Icon(Icons.language_rounded, color: AppColors.d100, size: 28),
                    ),
            ),
            // Nội dung bên phải
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tiêu đề
                    TextWidget(
                      text: item.name ?? meta?.title ?? '',
                      color: AppColors.white,
                      size: 13,
                      fontWeight: FontWeight.w600,
                      maxLines: 2,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      TextWidget(
                        text: description,
                        color: AppColors.white.withOpacityCompat(0.38),
                        size: 11,
                        maxLines: 1,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        // Source icon
                        if (appIcon != null) ...[
                          appIcon,
                          const SizedBox(width: 5),
                        ] else if (favicon.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: CacheImageWidget(
                              imageUrl: favicon,
                              width: 13,
                              height: 13,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(2),
                              errorWidget: Icon(
                                Icons.language_rounded,
                                size: 13,
                                color: AppColors.white.withOpacityCompat(0.38),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                        ] else ...[
                          const Icon(Icons.language_rounded, size: 13, color: AppColors.n80),
                          const SizedBox(width: 5),
                        ],
                        if (host.isNotEmpty)
                          Expanded(
                            child: TextWidget(
                              text: host,
                              color: AppColors.primary.withOpacityCompat(0.8),
                              size: 11,
                              fontWeight: FontWeight.w500,
                              maxLines: 1,
                            ),
                          ),
                        if (item.createdAt != null) ...[
                          const SizedBox(width: 6),
                          TextWidget(
                            text: _formatDate(item.createdAt!),
                            color: AppColors.white.withOpacityCompat(0.3),
                            size: 10,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime time) {
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
  }
}
