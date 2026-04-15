import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/core/ui/image/cache_image.dart';
import 'package:keep_link/core/ui/image/full_screen_image_page.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/link/application/controller/link_detail_controller.dart';
import 'package:keep_link/features/link/application/model/link_type.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HeroMediaWidget extends GetView<LinkDetailController> {
  const HeroMediaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (controller.imageUrl.isEmpty) return const SizedBox.shrink();

    return Obx(() {
      if (controller.isPlayingVideo.value && controller.webViewController != null) {
        return _WebViewPlayer(ctrl: controller.webViewController!);
      }

      return switch (controller.linkType) {
        LinkType.video => _ThumbnailWithPlay(),
        LinkType.document => _ThumbnailDocument(),
        LinkType.news => _ThumbnailNews(),
        LinkType.unknown => _ThumbnailNews(),
      };
    });
  }
}

// Video: có nút play
class _ThumbnailWithPlay extends GetView<LinkDetailController> {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Get.to(() => FullScreenImagePage(imageUrl: controller.imageUrl)),
    child: Hero(
      tag: controller.imageUrl,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _BaseThumbnail(imageUrl: controller.imageUrl),
          _PlayButton(onTap: controller.playVideo),
          const _SavedBadge(),
        ],
      ),
    ),
  );
}

// Tin tức: chỉ xem fullscreen, không có play
class _ThumbnailNews extends GetView<LinkDetailController> {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: controller.openWebView,
    child: Hero(
      tag: controller.imageUrl,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _BaseThumbnail(imageUrl: controller.imageUrl),
          const _ViewNowButton(), // ✅ thay _SavedBadge ở giữa
          const _SavedBadge(),
        ],
      ),
    ),
  );
}

class _ViewNowButton extends StatelessWidget {
  const _ViewNowButton();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.black.withOpacityCompat(0.6),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white, width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.language_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        TextWidget(text: "Xem ngay", textStyle: AppTextStyle.semiBold14, color: AppColors.white),
      ],
    ),
  );
}

// Document: không vào fullscreen, hiển thị icon tài liệu
class _ThumbnailDocument extends GetView<LinkDetailController> {
  @override
  Widget build(BuildContext context) => Hero(
    tag: controller.imageUrl,
    child: Stack(
      alignment: Alignment.center,
      children: [
        _BaseThumbnail(imageUrl: controller.imageUrl),
        _DocumentBadge(),
        const _SavedBadge(),
      ],
    ),
  );
}

// Thumbnail dùng chung
class _BaseThumbnail extends StatelessWidget {
  final String imageUrl;
  const _BaseThumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) => CacheImageWidget(
    borderRadius: BorderRadius.circular(16),
    imageUrl: imageUrl,
    height: Get.width * .8,
    width: double.infinity,
    fit: BoxFit.cover,
  );
}

class _DocumentBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.black.withOpacityCompat(0.6),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white54, width: 1.5),
    ),
    child: const Icon(Icons.description_outlined, color: Colors.white, size: 36),
  );
}

// Nút Play
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

// Badge "Saved recently"
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

class _WebViewPlayer extends GetView<LinkDetailController> {
  final WebViewController ctrl;
  const _WebViewPlayer({required this.ctrl});

  @override
  Widget build(BuildContext context) => Obx(
    () => controller.isExpanded.value
        ? _ExpandedWebView(ctrl: ctrl) // full screen
        : _InlineWebView(ctrl: ctrl), // trong bottom sheet
  );
}

// ── Inline (trong bottom sheet) ──────────────────────────
class _InlineWebView extends GetView<LinkDetailController> {
  final WebViewController ctrl;
  const _InlineWebView({required this.ctrl});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const _WebViewNavigationBar(),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: Get.width * .8,
          width: double.infinity,
          child: Stack(
            children: [
              WebViewWidget(
                controller: ctrl,
                // ✅ THÊM ĐOẠN NÀY ĐỂ ƯU TIÊN CUỘN WEBVIEW
                gestureRecognizers: {
                  Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
                  Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
                },
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ExpandedWebView extends GetView<LinkDetailController> {
  final WebViewController ctrl;
  const _ExpandedWebView({required this.ctrl});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.of(context).size.height * 0.7,
    width: double.infinity,
    child: Column(
      children: [
        const _WebViewNavigationBar(),
        const SizedBox(height: 8),
        Expanded(
          child: WebViewWidget(
            controller: ctrl,
            // ✅ THÊM ĐOẠN NÀY ĐỂ ƯU TIÊN CUỘN WEBVIEW
            gestureRecognizers: {
              Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
              Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
            },
          ),
        ),
      ],
    ),
  );
}

class _WebViewNavigationBar extends GetView<LinkDetailController> {
  const _WebViewNavigationBar();

  String _formatUrl(String rawUrl) {
    try {
      final uri = Uri.parse(rawUrl);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return rawUrl;
    }
  }

  @override
  Widget build(BuildContext context) => Obx(
    () => Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // ── Nút Home (về link gốc) ──
          _NavButton(
            icon: Icons.home_outlined,
            enable: true,
            onTap: controller.webGoHome,
            tooltip: "Về trang gốc",
          ),

          // ── Nút Reload ──
          _NavButton(icon: Icons.refresh_rounded, enable: true, onTap: controller.webReload),

          const SizedBox(width: 4),
          _VerticalDivider(),

          // ── URL hiện tại ──
          Expanded(
            child: GestureDetector(
              onTap: controller.webGoHome, // tap URL → về trang gốc
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: Colors.green, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formatUrl(controller.currentUrl.value),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // Loading indicator
                    if (controller.isWebLoading.value) ...[
                      const SizedBox(width: 6),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          _VerticalDivider(),
          const SizedBox(width: 4),

          // ── Nút Back ──
          _NavButton(
            icon: controller.isExpanded.value
                ? Icons.close_fullscreen_rounded
                : Icons.open_in_full_rounded,
            enable: true,
            onTap: controller.toggleExpand,
          ),

          // ── Nút Forward ──
          _NavButton(icon: Icons.close_rounded, enable: true, onTap: controller.closeWebView),
        ],
      ),
    ),
  );
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enable;
  final VoidCallback onTap;
  final String? tooltip;
  const _NavButton({required this.icon, required this.enable, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip ?? '',
    child: GestureDetector(
      onTap: enable ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Icon(
          icon,
          size: 18,
          color: enable ? Colors.white : Colors.white24, // ✅ mờ khi disable
        ),
      ),
    ),
  );
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 20, color: Colors.white12);
}
