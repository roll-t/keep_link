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
    final ctrl = Get.find<LinkCollectionController>();
    final meta = item.metaDataModel;
    final host = _extractHost(meta?.url);
    final favicon = meta?.favicon ?? meta?.appleIcon ?? '';
    final appIcon = _resolveAppIcon(host);

    return Obx(() {
      final isSelectionMode = ctrl.isSelectionMode.value;
      final isSelected = ctrl.selectedIds.contains(item.id);

      return GestureDetector(
        onLongPress: () {
          if (!isSelectionMode) ctrl.enterSelectionMode(item.id);
        },
        onTap: () {
          if (isSelectionMode) {
            ctrl.toggleSelectItem(item.id);
          } else {
            Get.toNamed(LinkDetailPage.routeName, arguments: item);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CacheImageWidget(
                  borderRadius: BorderRadius.circular(isSelected ? 10 : 12),
                  imageUrl: item.metaDataModel?.imageUrl ?? "/",
                ),
              ),
              // Dimming overlay when selected
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.black.withOpacityCompat(0.35),
                    ),
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
                            child: CacheImageWidget(
                              imageUrl: favicon,
                              width: 12,
                              height: 12,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(2),
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
    if (host.contains('tiktok.com')) return AppIcons.icLogoTiktok.show(size: 13);
    if (host.contains('twitter.com') || host.contains('x.com')) {
      return AppIcons.icLogoTwitter.show(size: 13);
    }
    if (host.contains('instagram.com')) return AppIcons.icLogoInstagram.show(size: 13);
    if (host.contains('facebook.com') || host.contains('fb.com')) {
      return AppIcons.icLogoFacebook.show(size: 13);
    }
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return AppIcons.icLogoYoutube.show(size: 13);
    }
    if (host.contains('google.com')) return AppIcons.icLogoGoogle.show(size: 13);
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.toNamed(LinkDetailPage.routeName, arguments: item);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 84),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail 16:9 tràn sát cạnh hoàn toàn, không border, không khoảng cách xung quanh
                SizedBox(
                  width: 136,
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
                    padding: const EdgeInsets.fromLTRB(0, 10, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextWidget(
                          text: item.name ?? meta?.title ?? '',
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
                            maxLines: 1,
                          ),
                        ],
                        const SizedBox(height: 6),
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
                                ),
                              ),
                            if (item.createdAt != null) ...[
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
                                text: _formatDate(item.createdAt!),
                                color: AppColors.white.withOpacityCompat(0.3),
                                size: 11.5,
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
        ),
      ),
    );
  }

  String _formatDate(DateTime time) {
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
  }
}
