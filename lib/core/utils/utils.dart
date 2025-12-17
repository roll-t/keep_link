import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_icons.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';
import 'package:keep_link/core/service/biometric_service.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
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

  // Hàm này dùng để verify ở các chỗ khác trong app (Ví dụ: trước khi xoá link, mở danh mục...)
  static Future<bool> verifySecurity() async {
    // Nếu cả 2 đều tắt -> Return true luôn (hoặc tuỳ logic gọi hàm)
    if (!AppGetStorage.isSecurityEnabled() && !AppGetStorage.isCategorySecurity()) return true;

    // Ưu tiên check vân tay nếu App Security đang bật và Vân tay đang bật
    if (AppGetStorage.isSecurityEnabled() && AppGetStorage.isFingerprintEnabled()) {
      final bioSuccess = await BiometricService.authenticate();
      if (bioSuccess) return true;
    }

    // Fallback sang PIN Dialog
    final completer = Completer<bool>();
    DialogUtils.showPinDialog(
      onCompleted: () {
        if (Get.isDialogOpen ?? false) Get.back();
        if (!completer.isCompleted) completer.complete(true);
      },
      onDismiss: () {
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    return completer.future;
  }

  // ✅ 1. SỬA LẠI HÀM NÀY: Phải nhận vào 'assetName' (đường dẫn icon)
  static Widget showIconsSvg(
    String assetName, {
    double? size,
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    return SvgPicture.asset(
      assetName,
      width: width ?? size,
      height: height ?? size,
      fit: fit,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }

  static void showToast(String message) {
    Fluttertoast.showToast(msg: message);
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
