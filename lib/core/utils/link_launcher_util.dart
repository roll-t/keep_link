import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/features/link/application/model/link_platform.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkLauncherUtil {
  LinkLauncherUtil._();

  static Future<bool> openUrl(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return false;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || (!uri.hasScheme && !trimmed.startsWith('http'))) {
      _showOpenError();
      return false;
    }

    final effectiveUri = uri.hasScheme ? uri : Uri.parse('https://$trimmed');
    final platform = LinkPlatformDetector.detect(effectiveUri.toString());
    var opened = false;

    try {
      if (platform.isApp) {
        // Đối với ứng dụng (YouTube, TikTok, Facebook, Instagram,...):
        // Thử mở bằng App native đã cài trên máy trước.
        try {
          opened = await launchUrl(
            effectiveUri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        } catch (error) {
          debugPrint('Open non-browser app error: $error');
        }

        if (!opened) {
          try {
            opened = await launchUrl(
              effectiveUri,
              mode: LaunchMode.externalApplication,
            );
          } catch (error) {
            debugPrint('Open external app error: $error');
          }
        }
      } else {
        // Đối với website thông thường:
        final isIncognito = AppGetStorage.isIncognitoMode();
        if (isIncognito) {
          try {
            final browser = InAppBrowser();
            await browser.openUrlRequest(
              urlRequest: URLRequest(url: WebUri(effectiveUri.toString())),
              settings: InAppBrowserClassSettings(
                browserSettings: InAppBrowserSettings(
                  presentationStyle: ModalPresentationStyle.FULL_SCREEN,
                ),
                webViewSettings: InAppWebViewSettings(
                  incognito: true,
                  cacheEnabled: false,
                  clearCache: true,
                  useHybridComposition: true,
                ),
              ),
            );
            opened = true;
          } catch (error) {
            debugPrint('Open Incognito InAppBrowser error: $error');
          }
        } else {
          try {
            opened = await launchUrl(
              effectiveUri,
              mode: LaunchMode.inAppBrowserView,
              browserConfiguration: const BrowserConfiguration(showTitle: true),
            );
          } catch (error) {
            debugPrint('Open Custom Tab error: $error');
          }
        }
      }

      // Fallback cuối cùng nếu chưa mở được:
      if (!opened) {
        try {
          opened = await launchUrl(
            effectiveUri,
            mode: LaunchMode.externalApplication,
          );
        } catch (error) {
          debugPrint('Open fallback external browser error: $error');
        }
      }

      if (!opened) {
        _showOpenError();
      }
      return opened;
    } catch (e) {
      debugPrint('LinkLauncherUtil openUrl error: $e');
      _showOpenError();
      return false;
    }
  }

  static void _showOpenError() {
    AppToast.error(
      'Không thể mở liên kết bằng trình duyệt hoặc ứng dụng phù hợp.',
    );
  }
}
