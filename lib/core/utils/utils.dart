import 'dart:io';

import 'package:flutter/material.dart';
import 'package:keep_link/core/config/app_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static void dimissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  static void ignoreException() {
    FlutterError.onError = (FlutterErrorDetails details) {
      final exception = details.exception;
      if (exception is HttpException && exception.message.contains('403')) {
        return;
      }
      FlutterError.presentError(details);
    };
  }

  static Future<void> lanchUrl(String url, {BuildContext? context}) async {
    final Uri uri = Uri.tryParse(url) ?? Uri();
    if (uri.toString().isEmpty) {
      if (context != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("URL không hợp lệ")));
      }
      return;
    }

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // fallback nếu không mở được
        if (context != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Không thể mở URL")));
        }
      }
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi khi mở URL: $e")));
      }
    }
  }

  static Widget? getSocialIcon({String? urlSocial, double iconSize = 20}) {
    if (urlSocial == null || urlSocial.isEmpty) return null;

    final uri = Uri.tryParse(urlSocial);
    final host = uri?.host.toLowerCase() ?? '';

    if (host.contains('tiktok.com')) {
      return AppIcons.icLogoTiktok.show(size: iconSize);
    } else if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return AppIcons.icLogoYoutube.show(size: iconSize);
    } else if (host.contains('facebook.com') || host.contains('fb.watch')) {
      return AppIcons.icLogoFacebook.show(size: iconSize);
    } else if (host.contains('instagram.com')) {
      return AppIcons.icLogoInstagram.show(size: iconSize);
    } else if (host.contains('x.com') || host.contains('twitter.com')) {
      return AppIcons.icLogoTwitter.show(size: iconSize);
    }

    return AppIcons.icLogoGoogle.show(size: iconSize);
  }
}
