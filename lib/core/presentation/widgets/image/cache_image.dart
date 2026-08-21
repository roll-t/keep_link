import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';

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
    double iconSize = 24;
    if (width != null && height != null) {
      iconSize = (width! < height! ? width! : height!) * 0.35;
      iconSize = iconSize.clamp(16.0, 30.0);
    } else if (width != null) {
      iconSize = (width! * 0.35).clamp(16.0, 30.0);
    }

    return Container(
      width: width,
      height: height,
      color: const Color(0xFF2C2E35),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: AppColors.n70.withOpacityCompat(0.65),
        size: iconSize,
      ),
    );
  }
}
