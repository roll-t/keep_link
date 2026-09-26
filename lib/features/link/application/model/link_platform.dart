import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_icons.dart';

class LinkPlatform {
  final String id;
  final String name;
  final bool isApp;
  final Widget Function({double size})? iconBuilder;
  final Color? brandColor;

  const LinkPlatform({
    required this.id,
    required this.name,
    required this.isApp,
    this.iconBuilder,
    this.brandColor,
  });

  /// Nhãn hiển thị cho nút mở (ví dụ: "Mở trong YouTube", "Mở website", "Mở ẩn danh")
  String getOpenLabel({bool isIncognito = false}) {
    if (isApp) {
      return "Open in @app".trParams({'app': name});
    }
    if (isIncognito) {
      return "Open Incognito".tr;
    }
    return "Open Website".tr;
  }

  /// Icon cho nút thao tác mở
  IconData getActionIcon({bool isIncognito = false}) {
    if (isApp) return Icons.open_in_new_rounded;
    if (isIncognito) return Icons.visibility_off_rounded;
    return Icons.language_rounded;
  }

  String get openLabel => getOpenLabel();
  IconData get actionIcon => getActionIcon();

  static const LinkPlatform website = LinkPlatform(
    id: 'website',
    name: 'Website',
    isApp: false,
  );
}

class LinkPlatformDetector {
  static LinkPlatform detect(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return LinkPlatform.website;
    }

    final lower = rawUrl.toLowerCase().trim();
    final uri = Uri.tryParse(lower);
    final scheme = uri?.scheme.toLowerCase() ?? '';
    final host = (uri?.host ?? lower).replaceFirst(RegExp(r'^www\.'), '');

    // ── YouTube ──────────────────────────────────────────────────────────────
    if (host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        scheme == 'vnd.youtube' ||
        scheme == 'youtube') {
      return LinkPlatform(
        id: 'youtube',
        name: 'YouTube',
        isApp: true,
        iconBuilder: ({double size = 20}) =>
            AppIcons.icLogoYoutube.show(size: size),
        brandColor: const Color(0xFFFF0000),
      );
    }

    // ── TikTok ───────────────────────────────────────────────────────────────
    if (host.contains('tiktok.com') || scheme == 'tiktok') {
      return LinkPlatform(
        id: 'tiktok',
        name: 'TikTok',
        isApp: true,
        iconBuilder: ({double size = 20}) =>
            AppIcons.icLogoTiktok.show(size: size),
        brandColor: const Color(0xFF000000),
      );
    }

    // ── Facebook ─────────────────────────────────────────────────────────────
    if (host.contains('facebook.com') ||
        host.contains('fb.com') ||
        host.contains('fb.watch') ||
        scheme == 'fb') {
      return LinkPlatform(
        id: 'facebook',
        name: 'Facebook',
        isApp: true,
        iconBuilder: ({double size = 20}) =>
            AppIcons.icLogoFacebook.show(size: size),
        brandColor: const Color(0xFF1877F2),
      );
    }

    // ── Instagram ────────────────────────────────────────────────────────────
    if (host.contains('instagram.com') ||
        host.contains('instagr.am') ||
        scheme == 'instagram') {
      return LinkPlatform(
        id: 'instagram',
        name: 'Instagram',
        isApp: true,
        iconBuilder: ({double size = 20}) =>
            AppIcons.icLogoInstagram.show(size: size),
        brandColor: const Color(0xFFE4405F),
      );
    }

    // ── X / Twitter ──────────────────────────────────────────────────────────
    if (host.contains('twitter.com') ||
        host.contains('x.com') ||
        host.contains('t.co') ||
        scheme == 'twitter') {
      return LinkPlatform(
        id: 'x',
        name: 'X',
        isApp: true,
        iconBuilder: ({double size = 20}) =>
            AppIcons.icLogoTwitter.show(size: size),
        brandColor: const Color(0xFF000000),
      );
    }

    // ── Google Maps ──────────────────────────────────────────────────────────
    if (host.contains('maps.google.') || lower.contains('goo.gl/maps')) {
      return LinkPlatform(
        id: 'google_maps',
        name: 'Google Maps',
        isApp: true,
        iconBuilder: ({double size = 20}) =>
            AppIcons.icLogoGoogle.show(size: size),
        brandColor: const Color(0xFF34A853),
      );
    }

    // ── Google Drive ─────────────────────────────────────────────────────────
    if (host.contains('drive.google.com')) {
      return LinkPlatform(
        id: 'google_drive',
        name: 'Google Drive',
        isApp: true,
        iconBuilder: ({double size = 20}) =>
            AppIcons.icLogoGoogle.show(size: size),
        brandColor: const Color(0xFF1EA362),
      );
    }

    // ── Google Docs / Sheets / Slides ────────────────────────────────────────
    if (host.contains('docs.google.com')) {
      return LinkPlatform(
        id: 'google_docs',
        name: 'Google Docs',
        isApp: true,
        iconBuilder: ({double size = 20}) =>
            AppIcons.icLogoGoogle.show(size: size),
        brandColor: const Color(0xFF4285F4),
      );
    }

    // ── Google ───────────────────────────────────────────────────────────────
    if (host.contains('google.com')) {
      return LinkPlatform(
        id: 'google',
        name: 'Google',
        isApp: true,
        iconBuilder: ({double size = 20}) =>
            AppIcons.icLogoGoogle.show(size: size),
        brandColor: const Color(0xFF4285F4),
      );
    }

    // ── Threads ──────────────────────────────────────────────────────────────
    if (host.contains('threads.net') || scheme == 'barcelona') {
      return const LinkPlatform(
        id: 'threads',
        name: 'Threads',
        isApp: true,
        brandColor: Color(0xFF000000),
      );
    }

    // ── Spotify ──────────────────────────────────────────────────────────────
    if (host.contains('spotify.com') ||
        host.contains('spoti.fi') ||
        scheme == 'spotify') {
      return const LinkPlatform(
        id: 'spotify',
        name: 'Spotify',
        isApp: true,
        brandColor: Color(0xFF1DB954),
      );
    }

    // ── Telegram ─────────────────────────────────────────────────────────────
    if (host.contains('t.me') ||
        host.contains('telegram.org') ||
        host.contains('telegram.me') ||
        scheme == 'tg') {
      return const LinkPlatform(
        id: 'telegram',
        name: 'Telegram',
        isApp: true,
        brandColor: Color(0xFF229ED9),
      );
    }

    // ── Zalo ─────────────────────────────────────────────────────────────────
    if (host.contains('zalo.me') || scheme == 'zalo') {
      return const LinkPlatform(
        id: 'zalo',
        name: 'Zalo',
        isApp: true,
        brandColor: Color(0xFF0068FF),
      );
    }

    // ── GitHub ───────────────────────────────────────────────────────────────
    if (host.contains('github.com')) {
      return const LinkPlatform(
        id: 'github',
        name: 'GitHub',
        isApp: true,
        brandColor: Color(0xFF24292E),
      );
    }

    // ── Reddit ───────────────────────────────────────────────────────────────
    if (host.contains('reddit.com') || host.contains('redd.it')) {
      return const LinkPlatform(
        id: 'reddit',
        name: 'Reddit',
        isApp: true,
        brandColor: Color(0xFFFF4500),
      );
    }

    // ── Shopee ───────────────────────────────────────────────────────────────
    if (host.contains('shopee.vn') ||
        host.contains('shopee.com') ||
        host.contains('shp.ee')) {
      return const LinkPlatform(
        id: 'shopee',
        name: 'Shopee',
        isApp: true,
        brandColor: Color(0xFFEE4D2D),
      );
    }

    // ── Lazada ───────────────────────────────────────────────────────────────
    if (host.contains('lazada.vn') ||
        host.contains('lazada.com') ||
        host.contains('s.lazada.vn')) {
      return const LinkPlatform(
        id: 'lazada',
        name: 'Lazada',
        isApp: true,
        brandColor: Color(0xFF0F146D),
      );
    }

    // ── Pinterest ────────────────────────────────────────────────────────────
    if (host.contains('pinterest.com') || host.contains('pin.it')) {
      return const LinkPlatform(
        id: 'pinterest',
        name: 'Pinterest',
        isApp: true,
        brandColor: Color(0xFFE60023),
      );
    }

    // ── LinkedIn ─────────────────────────────────────────────────────────────
    if (host.contains('linkedin.com')) {
      return const LinkPlatform(
        id: 'linkedin',
        name: 'LinkedIn',
        isApp: true,
        brandColor: Color(0xFF0A66C2),
      );
    }

    // ── Netflix ──────────────────────────────────────────────────────────────
    if (host.contains('netflix.com')) {
      return const LinkPlatform(
        id: 'netflix',
        name: 'Netflix',
        isApp: true,
        brandColor: Color(0xFFE50914),
      );
    }

    // ── Discord ──────────────────────────────────────────────────────────────
    if (host.contains('discord.com') || host.contains('discord.gg')) {
      return const LinkPlatform(
        id: 'discord',
        name: 'Discord',
        isApp: true,
        brandColor: Color(0xFF5865F2),
      );
    }

    // Mặc định: Website thông thường
    return LinkPlatform.website;
  }
}
