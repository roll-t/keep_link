import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

class DownloadedVideoArguments {
  final String filePath;
  final String title;

  const DownloadedVideoArguments({
    required this.filePath,
    required this.title,
  });
}

class DownloadedVideoController extends GetxController {
  final String filePath;
  final String title;

  DownloadedVideoController({
    required this.filePath,
    required this.title,
  });

  final hasError = false.obs;
  InAppWebViewController? webViewController;

  String get displayTitle => title.isEmpty ? 'watch_video'.tr : title;

  String get playerHtml {
    final source = const HtmlEscape(
      HtmlEscapeMode.attribute,
    ).convert(Uri.file(filePath).toString());

    return '''
      <!doctype html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
          <style>
            html, body { margin: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
            video { width: 100%; height: 100%; object-fit: contain; background: #000; }
          </style>
        </head>
        <body>
          <video controls autoplay playsinline preload="auto" onerror="window.flutter_inappwebview.callHandler('videoError')">
            <source src="$source">
          </video>
        </body>
      </html>
    ''';
  }

  void onWebViewCreated(InAppWebViewController controller) {
    webViewController = controller;
    controller.addJavaScriptHandler(
      handlerName: 'videoError',
      callback: (_) {
        hasError.value = true;
        return null;
      },
    );
  }
}
