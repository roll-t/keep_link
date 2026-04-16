import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/link/application/controller/link_collection_controller.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/application/model/link_type.dart';
import 'package:keep_link/features/link/presentation/link_add/page/add_link_page.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LinkDetailController extends GetxController {
  final LinkModel link;
  LinkDetailController({required this.link});

  final isPlayingVideo = false.obs;
  final isExpanded = false.obs;
  final canGoBack = false.obs;
  final canGoForward = false.obs;
  final currentUrl = ''.obs;
  final isWebLoading = false.obs;
  WebViewController? webViewController;

  late final String url = link.metaDataModel?.url ?? '';
  late final LinkType linkType = LinkTypeDetector.detect(url);

  bool get isVideo => linkType == LinkType.video;
  String get imageUrl => link.metaDataModel?.imageUrl ?? '';
  String get title => link.metaDataModel?.title ?? link.name ?? '';
  String get description => link.metaDataModel?.description ?? '';
  bool get isTikTok => url.contains("tiktok.com");

  // --- WebView Logic ---

  void openWebView() {
    if (url.isEmpty) return;
    isExpanded.value = true;
    isPlayingVideo.value = true;
    _initWebViewController(url);
  }

  void playVideo() {
    if (url.isEmpty) return;
    isExpanded.value = true;
    isPlayingVideo.value = true;
    _initWebViewController(url);
  }

  void _initWebViewController(String targetUrl) {
    if (webViewController != null) return;

    final userAgent = isTikTok
        ? "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1"
        : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36";

    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent(userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            isWebLoading.value = true;
            currentUrl.value = url;
            _updateNavState();
          },
          onPageFinished: (url) {
            isWebLoading.value = false;
            currentUrl.value = url;
            _updateNavState();

            // 1. Tiêm JS chặn quảng cáo chung cho mọi trang
            webViewController?.runJavaScript(_adBlockerJS);

            // 2. Tiêm JS tối ưu riêng cho TikTok
            if (url.contains("tiktok.com")) {
              webViewController?.runJavaScript(_tiktokJS);
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url.toLowerCase());

            // --- CHẶN QUẢNG CÁO TẦNG MẠNG ---
            final adDomains = [
              'doubleclick.net',
              'googleadservices.com',
              'googlesyndication.com',
              'moatads.com',
              'taboola.com',
              'outbrain.com',
              'adnxs.com',
            ];

            if (adDomains.any((domain) => uri.host.contains(domain))) {
              return NavigationDecision.prevent;
            }
            // ---------------------------------

            if (!uri.scheme.startsWith('http')) return NavigationDecision.prevent;

            if (uri.host.contains('tiktok.com') && uri.path.contains('download')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(targetUrl));
  }

  Future<void> _updateNavState() async {
    if (webViewController == null) return;
    final results = await Future.wait([
      webViewController!.canGoBack(),
      webViewController!.canGoForward(),
    ]);
    canGoBack.value = results[0];
    canGoForward.value = results[1];
  }

  Future<void> webReload() async => await webViewController?.reload();
  Future<void> webGoHome() async => await webViewController?.loadRequest(Uri.parse(url));
  void toggleExpand() => isExpanded.toggle();

  void closeWebView() {
    isPlayingVideo.value = false;
    isExpanded.value = false;
    canGoBack.value = false;
    canGoForward.value = false;
    currentUrl.value = '';
    isWebLoading.value = false;
    webViewController = null;
  }

  void copyUrl() {
    if (url.isEmpty) return;
    Clipboard.setData(ClipboardData(text: url));
    Fluttertoast.showToast(msg: "Đã sao chép");
  }

  void openInApp() {
    if (url.isNotEmpty) Utils.lanchUrl(url);
  }

  void goToEdit() {
    Get.back();
    Get.toNamed(AddLinkPage.routeName, arguments: link)?.then((success) {
      if (success == true) {
        Get.find<LinkCollectionController>().onRefreshData();
      }
    });
  }

  void deleteLink() => Get.find<LinkCollectionController>().onDeleteLink(link.id);

  // --- JAVASCRIPT BLOCKERS ---

  // JS Chặn quảng cáo chung
  static const String _adBlockerJS = '''
    (function() {
      const adSelectors = [
        '.adsbygoogle', 'ins.adsbygoogle', '[id^="google_ads_"]', 
        'iframe[src*="doubleclick.net"]', '.ad-box', '.ad-container', '.ad-unit'
      ];
      function removeAds() {
        adSelectors.forEach(s => {
          document.querySelectorAll(s).forEach(el => el.remove());
        });
      }
      removeAds();
      setTimeout(removeAds, 2000); // Chạy thêm một lần sau 2s để diệt quảng cáo load chậm
    })();
  ''';

  // JS Cho TikTok
  static const String _tiktokJS = '''
    window.open = function() { return null; };
    var meta = document.querySelector('meta[name="viewport"]') || document.createElement('meta');
    meta.name = 'viewport';
    meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
    if (!meta.parentNode) document.getElementsByTagName('head')[0].appendChild(meta);

    function hideAppPrompts() {
      const badSelectors = ['.tiktok-banner', '.download-wrapper', '.open-app-button', '.css-1q0z0m3-ButtonDownload', '[class*="BannerContainer"]', '#TUX-portal-container', '.css-1176r2e-DivBannerContainer'];
      badSelectors.forEach(s => document.querySelectorAll(s).forEach(el => el.remove()));
      document.body.style.overflow = 'auto';
      document.documentElement.style.overflow = 'auto';
    }
    hideAppPrompts();
    setInterval(hideAppPrompts, 1000);
  ''';
}
