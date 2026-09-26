import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/image/cache_image.dart';
import 'package:keep_link/core/presentation/widgets/tab/app_segmented_tab.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/link_detail_controller.dart';

class DestinationCard extends GetView<LinkDetailController> {
  const DestinationCard({super.key});

  Widget _buildLeadingIcon(BuildContext context) {
    final platform = controller.linkPlatform;
    final favicon =
        controller.link.metaDataModel?.favicon ?? controller.link.metaDataModel?.appleIcon ?? '';

    // 1. Nếu là app có logo asset (YouTube, TikTok, Facebook, Instagram, X, Google...)
    if (platform.iconBuilder != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (platform.brandColor ?? AppColors.accentViolet).withOpacityCompat(0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (platform.brandColor ?? AppColors.white).withOpacityCompat(0.12),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: platform.iconBuilder!(size: 22),
      );
    }

    // 2. Nếu có favicon từ metadata (website thông thường hoặc app)
    if (favicon.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacityCompat(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.white.withOpacityCompat(0.08), width: 1),
        ),
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CacheImageWidget(
            imageUrl: favicon,
            width: 22,
            height: 22,
            fit: BoxFit.contain,
            errorWidget: Icon(
              platform.isApp ? Icons.apps_rounded : Icons.language_rounded,
              color: AppColors.primaryBright,
              size: 20,
            ),
          ),
        ),
      );
    }

    // 3. Fallback: Icon app hoặc icon website
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: platform.isApp
            ? AppColors.accentViolet.withOpacityCompat(0.2)
            : AppColors.primary.withOpacityCompat(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (platform.isApp ? AppColors.accentViolet : AppColors.primary).withOpacityCompat(
            0.2,
          ),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        platform.isApp ? Icons.apps_rounded : Icons.language_rounded,
        color: platform.isApp ? AppColors.white : AppColors.primaryBright,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Không có URL lẫn địa chỉ để hiển thị (vd: metaData bị null) — tránh vẽ
    // một khung rỗng chỉ có padding, tốn diện tích màn hình vô ích.
    if (controller.url.isEmpty && !controller.hasLocation) {
      return const SizedBox.shrink();
    }

    final platform = controller.linkPlatform;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.url.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWidget(
                  text: "Original Destination".tr,
                  textStyle: AppTextStyle.bold12,
                  color: AppColors.grey,
                ),

                // Link website: chỉ chừa lại switch ẩn danh và public
                if (!platform.isApp)
                  Obx(() {
                    final isIncognito = controller.isIncognito.value;
                    return SizedBox(
                      width: 68,
                      height: 24,
                      child: AppSegmentedTab(
                        selectedIndex: isIncognito ? 1 : 0,
                        height: 24,
                        padding: 2,
                        borderRadius: 20,
                        backgroundColor: AppColors.background.withValues(alpha: .52),
                        borderColor: AppColors.white.withValues(alpha: .07),
                        selectedColor: AppColors.primary,
                        selectedGradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primaryBright, AppColors.primary],
                        ),
                        onChanged: (index) {
                          HapticFeedback.selectionClick();
                          controller.toggleIncognito(index == 1);
                        },
                        tabs: [
                          AppSegmentTabItem(
                            label: '',
                            semanticLabel: 'Public'.tr,
                            icon: SizedBox.square(
                              dimension: 16,
                              child: Center(
                                child: Icon(
                                  Icons.public_rounded,
                                  size: 13,
                                  color: !isIncognito ? AppColors.white : AppColors.n70,
                                ),
                              ),
                            ),
                          ),
                          AppSegmentTabItem(
                            label: '',
                            semanticLabel: 'Incognito'.tr,
                            icon: SizedBox.square(
                              dimension: 16,
                              child: Center(
                                child: AppVectors.icAnonymous.show(
                                  size: 13,
                                  color: isIncognito ? AppColors.white : AppColors.n70,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 12),
            _LinkDestinationRow(controller: controller, leadingIcon: _buildLeadingIcon(context)),
          ],
          if (controller.hasLocation) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.openInMaps,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.successDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.map_rounded, color: AppColors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextWidget(
                      text: controller.address,
                      textStyle: AppTextStyle.regular14,
                      color: AppColors.successBright,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.open_in_new, color: AppColors.successBright, size: 18),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkDestinationRow extends StatefulWidget {
  final LinkDetailController controller;
  final Widget leadingIcon;

  const _LinkDestinationRow({required this.controller, required this.leadingIcon});

  @override
  State<_LinkDestinationRow> createState() => _LinkDestinationRowState();
}

class _LinkDestinationRowState extends State<_LinkDestinationRow> {
  final GlobalKey _rowKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;

  void _showCopyTag() {
    _dismissCopyTag();
    HapticFeedback.mediumImpact();

    final renderBox = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !mounted) return;

    final tileOffset = renderBox.localToGlobal(Offset.zero);
    final tileSize = renderBox.size;
    final overlayState = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        const tagHeight = 36.0;
        final top = (tileOffset.dy - tagHeight - 8) < 50
            ? (tileOffset.dy + tileSize.height + 8)
            : (tileOffset.dy - tagHeight - 8);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _dismissCopyTag,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              top: top,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1.0),
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.controller.copyUrl();
                        _dismissCopyTag();
                      },
                      child: Container(
                        height: tagHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: AppColors.primaryBright,
                            ),
                            const SizedBox(width: 6),
                            TextWidget(
                              text: "Copy Link".tr,
                              textStyle: AppTextStyle.semiBold12,
                              color: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlayState.insert(_overlayEntry!);
    _dismissTimer = Timer(const Duration(seconds: 4), _dismissCopyTag);
  }

  void _dismissCopyTag() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _dismissCopyTag();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _rowKey,
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_overlayEntry != null) {
          _dismissCopyTag();
          return;
        }
        widget.controller.openDestination();
      },
      onLongPress: _showCopyTag,
      child: Row(
        children: [
          widget.leadingIcon,
          const SizedBox(width: 12),
          Expanded(
            child: TextWidget(
              text: widget.controller.url,
              textStyle: AppTextStyle.regular14,
              color: AppColors.primaryBright,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.open_in_new_rounded, color: AppColors.white70, size: 18),
        ],
      ),
    );
  }
}
