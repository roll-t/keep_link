import 'package:flutter/material.dart';
import 'package:keep_link/core/config/assets/app_icons.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

/// Thống kê số lượng link theo nguồn (domain).
class SourceStat {
  final String host; // normalized key, e.g. "tiktok.com"
  final String label; // display name, e.g. "TikTok"
  final int count;
  const SourceStat({
    required this.host,
    required this.label,
    required this.count,
  });
}

class LinkSourceUtil {
  /// Chuẩn hóa URL thành domain key chuẩn (vd: "vm.tiktok.com" -> "tiktok.com").
  static String normalizeHost(String? url) {
    if (url == null || url.isEmpty) return '';
    try {
      final normalizedUrl = url.contains('://') ? url : 'https://$url';
      final h = Uri.parse(
        normalizedUrl,
      ).host.toLowerCase().replaceFirst('www.', '');
      if (h.contains('tiktok.com')) return 'tiktok.com';
      if (h.contains('youtu.be') || h.contains('youtube.com')) {
        return 'youtube.com';
      }
      if (h.contains('instagram.com')) return 'instagram.com';
      if (h.contains('facebook.com') ||
          h.contains('fb.com') ||
          h.contains('fb.watch')) {
        return 'facebook.com';
      }
      if (h.contains('twitter.com') || h.contains('x.com')) return 'x.com';
      if (h.contains('google.com')) return 'google.com';
      return h;
    } catch (_) {
      return '';
    }
  }

  /// Tên nhãn hiển thị cho host
  static String labelForHost(String host) {
    const labels = {
      'tiktok.com': 'TikTok',
      'youtube.com': 'YouTube',
      'instagram.com': 'Instagram',
      'facebook.com': 'Facebook',
      'x.com': 'X',
      'google.com': 'Google',
    };
    return labels[host] ?? host;
  }

  /// Icon thương hiệu của host
  static Widget sourceIcon(String host, {double size = 16}) {
    if (host.contains('tiktok.com')) {
      return AppIcons.icLogoTiktok.show(size: size);
    }
    if (host.contains('youtube.com')) {
      return AppIcons.icLogoYoutube.show(size: size);
    }
    if (host.contains('instagram.com')) {
      return AppIcons.icLogoInstagram.show(size: size);
    }
    if (host.contains('facebook.com')) {
      return AppIcons.icLogoFacebook.show(size: size);
    }
    if (host.contains('x.com')) {
      return AppIcons.icLogoTwitter.show(size: size);
    }
    if (host.contains('google.com')) {
      return AppIcons.icLogoGoogle.show(size: size);
    }
    return Icon(
      Icons.language_rounded,
      size: size,
      color: AppColors.white.withOpacityCompat(0.6),
    );
  }

  /// Tính toán danh sách các nguồn từ tập hợp links
  static List<SourceStat> computeSources(
    Iterable<LinkModel> links, {
    Set<String> privateCategoryIds = const {},
  }) {
    final counter = <String, int>{};
    for (final link in links) {
      if (link.categoryId != null &&
          privateCategoryIds.contains(link.categoryId)) {
        continue;
      }
      final host = normalizeHost(link.metaDataModel?.url);
      if (host.isEmpty) continue;
      counter[host] = (counter[host] ?? 0) + 1;
    }
    final sorted = counter.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .map(
          (e) => SourceStat(
            host: e.key,
            label: labelForHost(e.key),
            count: e.value,
          ),
        )
        .toList();
  }
}
