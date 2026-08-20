import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';

class CacheImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final IconData emptyIcon;

  const CacheImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.emptyIcon = Icons.photo_outlined,
  });

  bool _isValidUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  @override
  Widget build(BuildContext context) {
    final valid = _isValidUrl(imageUrl);

    Widget fallback = errorWidget ??
        _DefaultEmptyImage(
          width: width,
          height: height,
          icon: emptyIcon,
        );

    if (!valid) {
      if (borderRadius != null) {
        return ClipRRect(borderRadius: borderRadius!, child: fallback);
      }
      return fallback;
    }

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl!.trim(),
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      errorListener: (_) {
        // Silently catch remote server failures (403, 404, 501, SSL error)
      },
      // No spinner while loading — show the same empty placeholder as the
      // error state, and swap straight to the image once it's ready.
      placeholder: (context, url) => placeholder ?? fallback,
      errorWidget: (context, url, error) => fallback,
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

class _DefaultEmptyImage extends StatelessWidget {
  final double? width;
  final double? height;
  final IconData icon;

  const _DefaultEmptyImage({
    this.width,
    this.height,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = (width != null && width! < 60) || (height != null && height! < 60);

    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF252830),
            Color(0xFF1B1D22),
            Color(0xFF141519),
          ],
        ),
      ),
      child: Center(
        child: isCompact
            ? Icon(
                icon,
                color: AppColors.t300.withValues(alpha: 0.5),
                size: (width != null) ? (width! * 0.45).clamp(10, 20) : 14,
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle ambient glow in background
                  Container(
                    width: (width != null) ? width! * 0.6 : 50,
                    height: (height != null) ? height! * 0.6 : 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Modern glassmorphism badge
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.04),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.t200.withValues(alpha: 0.75),
                      size: (width != null && width! < 90) ? 18 : 22,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
