import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/application/model/link_type.dart';
import 'package:keep_link/features/link/module/link_add/presentation/page/add_link_page.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/link_collection_controller.dart';

class LinkDetailController extends GetxController {
  final LinkModel link;
  LinkDetailController({required this.link});

  final isPlayingVideo = false.obs;
  final isExpanded = false.obs;
  final canGoBack = false.obs;
  final canGoForward = false.obs;
  final currentUrl = ''.obs;
  final isWebLoading = false.obs;
  InAppWebViewController? webViewController;

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
  }

  void playVideo() {
    if (url.isEmpty) return;
    isExpanded.value = true;
    isPlayingVideo.value = true;
  }

  // CÁC CALLBACK ĐƯỢC DỜI TỪ _initWebViewController ĐỂ UI GỌI
  void onPageStarted(String? newUrl) {
    isWebLoading.value = true;
    currentUrl.value = newUrl ?? '';
    _updateNavState();
  }

  void onPageFinished(String? newUrl) {
    isWebLoading.value = false;
    currentUrl.value = newUrl ?? '';
    _updateNavState();

    // 1. Tiêm JS chặn quảng cáo chung cho mọi trang
    webViewController?.evaluateJavascript(source: _adBlockerJS);

    // 2. Tiêm JS tối ưu riêng cho TikTok
    if (newUrl != null && newUrl.contains("tiktok.com")) {
      webViewController?.evaluateJavascript(source: _tiktokJS);
    }
  }

  Future<NavigationActionPolicy> shouldOverrideUrlLoading(NavigationAction navigationAction) async {
    final uri = navigationAction.request.url;
    if (uri == null) return NavigationActionPolicy.ALLOW;

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
      return NavigationActionPolicy.CANCEL;
    }
    // ---------------------------------

    if (!uri.scheme.startsWith('http')) return NavigationActionPolicy.CANCEL;

    if (uri.host.contains('tiktok.com') && uri.path.contains('download')) {
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
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
  Future<void> webGoHome() async {
    if (url.isNotEmpty) {
      await webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    }
  }

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
    Fluttertoast.showToast(msg: "Chân thành đã sao chép");
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
