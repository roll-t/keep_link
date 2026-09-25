import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_icons.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/image/cache_image.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/link_collection_controller.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/page/link_detail.dart';

class LinkItem extends StatelessWidget {
  final int index;
  final LinkModel item;
  final LinkCollectionController controller;
  const LinkItem({super.key, required this.index, required this.item, required this.controller});

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
    if (host.contains('tiktok.com')) {
      return AppIcons.icLogoTiktok.show(size: 12);
    }
    if (host.contains('twitter.com') || host.contains('x.com')) {
      return AppIcons.icLogoTwitter.show(size: 12);
    }
    if (host.contains('instagram.com')) {
      return AppIcons.icLogoInstagram.show(size: 12);
    }
    if (host.contains('facebook.com') || host.contains('fb.com')) {
      return AppIcons.icLogoFacebook.show(size: 12);
    }
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return AppIcons.icLogoYoutube.show(size: 12);
    }
    if (host.contains('google.com')) {
      return AppIcons.icLogoGoogle.show(size: 12);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final meta = item.metaDataModel;
    final host = _extractHost(meta?.url);
    final favicon = meta?.favicon ?? meta?.appleIcon ?? '';
    final appIcon = _resolveAppIcon(host);

    return Obx(() {
      final isSelectionMode = controller.isSelectionMode.value;
      final isSelected = controller.selectedIds.contains(item.id);

      return RepaintBoundary(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () {
            if (!controller.isSelectionMode.value) {
              controller.enterSelectionMode(item.id);
            }
          },
          onTap: () {
            if (controller.isSelectionMode.value) {
              controller.toggleSelectItem(item.id);
            } else {
              Get.toNamed(LinkDetailPage.routeName, arguments: item);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CacheImageWidget(
                    borderRadius: BorderRadius.circular(8),
                    imageUrl: item.metaDataModel?.imageUrl ?? '',
                    memCacheWidth: 640,
                    memCacheHeight: 640,
                  ),
                ),
                // Dimming overlay when selected
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.black.withOpacityCompat(0.35),
                        border: Border.all(color: AppColors.primaryDim, width: 2),
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.white.withOpacityCompat(.8),
                    ),
                    child: TextWidget(
                      text: (item.name?.trim().isNotEmpty ?? false)
                          ? item.name!
                          : (meta?.title ?? 'Link'),
                      textAlign: TextAlign.center,
                      textStyle: AppTextStyle.semiBold14,
                      color: AppColors.t700,
                      maxLines: 3,
                    ),
                  ),
                ),
                if (host.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Align(
                      alignment: Alignment.centerLeft,
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
                                child: CacheImageWidget(
                                  imageUrl: favicon,
                                  width: 12,
                                  height: 12,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(2),
                                  memCacheWidth: 48,
                                  memCacheHeight: 48,
                                  errorWidget: const Icon(
                                    Icons.language_rounded,
                                    size: 12,
                                    color: AppColors.n80,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ] else ...[
                              const Icon(Icons.language_rounded, size: 12, color: AppColors.n80),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: TextWidget(
                                text: host,
                                color: AppColors.white,
                                size: 10,
                                fontWeight: FontWeight.w500,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Checkmark for selection mode
                if (isSelectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primaryDim
                            : AppColors.black.withOpacityCompat(0.45),
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, size: 14, color: AppColors.white)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─── Horizontal list item dùng cho trang search ───────────────────────────────
//
// Feed edge-to-edge kiểu YouTube/Facebook: không còn card riêng (nền + viền +
// bo góc bọc cả hàng) — thumbnail 16:9 sát mép trái, nội dung tràn tới sát mép
// phải, chỉ có 1 đường kẻ mảnh phân cách giữa các item. List cha
// (_ResultBody) bỏ padding ngang để item thật sự chạm mép màn hình.

class LinkListItem extends StatelessWidget {
  final int index;
  final LinkModel item;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double thumbnailWidth;

  const LinkListItem({
    super.key,
    required this.index,
    required this.item,
    this.onTap,
    this.trailing,
    this.thumbnailWidth = 136,
  });

  String _extractHost(String? url) {
    if (url == null || url.isEmpty) return '';
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return '';
    }
  }

  Widget? _resolveAppIcon(String host) {
    if (host.contains('tiktok.com')) {
      return AppIcons.icLogoTiktok.show(size: 13);
    }
    if (host.contains('twitter.com') || host.contains('x.com')) {
      return AppIcons.icLogoTwitter.show(size: 13);
    }
    if (host.contains('instagram.com')) {
      return AppIcons.icLogoInstagram.show(size: 13);
    }
    if (host.contains('facebook.com') || host.contains('fb.com')) {
      return AppIcons.icLogoFacebook.show(size: 13);
    }
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return AppIcons.icLogoYoutube.show(size: 13);
    }
    if (host.contains('google.com')) {
      return AppIcons.icLogoGoogle.show(size: 13);
    }
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
    final itemName = item.name;
    final metaTitle = meta?.title;
    final title = (itemName != null && itemName.isNotEmpty)
        ? itemName
        : (metaTitle != null && metaTitle.isNotEmpty)
        ? metaTitle
        : (meta?.url ?? '');
    final displayDate = item.createdAt ?? item.updatedAt;
    final minH = (thumbnailWidth * 9 / 16).roundToDouble();

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap:
            onTap ??
            () {
              Get.toNamed(LinkDetailPage.routeName, arguments: item);
            },
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minH < 76 ? 76 : minH),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail 16:9 tràn sát cạnh hoàn toàn, không border, không khoảng cách xung quanh
                SizedBox(
                  width: thumbnailWidth,
                  child: CacheImageWidget(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    emptyIcon: Icons.photo_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                // Nội dung bên phải
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 10, trailing != null ? 8 : 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Source icon, host, date
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
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
                                          color: AppColors.white.withOpacityCompat(0.35),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                  ] else ...[
                                    Icon(
                                      Icons.language_rounded,
                                      size: 13,
                                      color: AppColors.white.withOpacityCompat(0.35),
                                    ),
                                    const SizedBox(width: 5),
                                  ],
                                  if (host.isNotEmpty)
                                    Flexible(
                                      child: TextWidget(
                                        text: host,
                                        color: AppColors.white.withOpacityCompat(0.5),
                                        size: 12,
                                        fontWeight: FontWeight.w500,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  if (displayDate != null) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Container(
                                        width: 3,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: AppColors.white.withOpacityCompat(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    TextWidget(
                                      text: _formatDate(displayDate),
                                      color: AppColors.white.withOpacityCompat(0.3),
                                      size: 11.5,
                                      maxLines: 1,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                          ],
                        ),
                        const SizedBox(height: 6),

                        TextWidget(
                          text: title,
                          color: AppColors.white,
                          size: 14,
                          fontWeight: FontWeight.w600,
                          maxLines: 2,
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          TextWidget(
                            text: description,
                            color: AppColors.white.withOpacityCompat(0.4),
                            size: 12,
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime time) {
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
  }
}
