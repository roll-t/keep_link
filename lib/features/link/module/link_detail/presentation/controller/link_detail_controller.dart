import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/utils/app_toast.dart';
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
  // Trang chính (không phải sub-resource) tải lỗi — vd. site chặn kết nối,
  // SSL handshake fail... Không có cờ này thì người dùng chỉ thấy màn hình
  // đen im lìm không rõ đang tải hay đã hỏng, không biết phải làm gì tiếp.
  final hasLoadError = false.obs;
  InAppWebViewController? webViewController;

  late final String url = link.metaDataModel?.url ?? '';
  late final LinkType linkType = LinkTypeDetector.detect(url);

  bool get isVideo => linkType == LinkType.video;
  String get imageUrl => link.metaDataModel?.imageUrl ?? '';
  String get title => link.metaDataModel?.title ?? link.name ?? '';
  String get description => link.metaDataModel?.description ?? '';
  bool get isTikTok => url.contains("tiktok.com");
  String get address => link.metaDataModel?.address ?? '';
  bool get hasLocation => address.isNotEmpty;

  // ── Ad / tracker blocking ────────────────────────────────────────────────

  /// Domain quảng cáo/tracker chặn ở tầng network (request bị huỷ trước khi
  /// tải) — dùng chung cho cả điều hướng trang (shouldOverrideUrlLoading) lẫn
  /// từng sub-resource (ảnh/script/iframe quảng cáo) trong shouldInterceptRequest.
  /// Chặn ở đây rẻ hơn nhiều so với JS xoá DOM sau khi đã tải xong: khỏi tốn
  /// băng thông + thời gian parse/layout cho nội dung quảng cáo, trang đỡ giật/lag.
  static const List<String> _adDomains = [
    'doubleclick.net',
    'googleadservices.com',
    'googlesyndication.com',
    'google-analytics.com',
    'googletagmanager.com',
    'googletagservices.com',
    'moatads.com',
    'taboola.com',
    'outbrain.com',
    'adnxs.com',
    'popads.net',
    'popcash.net',
    'propellerads.com',
    'exoclick.com',
    'adsterra.com',
    'hilltopads.net',
    'mgid.com',
    'revcontent.com',
    'adskeeper.com',
    'clickadu.com',
    'admaven.com',
  ];

  static bool _isAdHost(String host) => _adDomains.any((domain) => host.contains(domain));

  static String get _adDomainsJsArray => '[${_adDomains.map((d) => "'$d'").join(',')}]';

  // ── Domain lock (chỉ cho điều hướng trong cùng trang gốc) ──────────────────

  /// Domain của trang đang xem, "khoá" lại sau lần tải thành công đầu tiên.
  /// Null nghĩa là còn đang trong chuỗi redirect ban đầu (vd. motchilltv.ltd
  /// → motchilltv.yt) nên chưa chặn gì — chặn sớm quá sẽ chặn nhầm chính
  /// redirect hợp lệ của trang, y hệt lỗi từng gặp với shouldInterceptRequest.
  String? _lockedHost;

  /// true nếu [host] cùng domain (hoặc là subdomain) với trang đang khoá.
  /// Còn null (chưa khoá) thì cho qua hết — domain lock chỉ có tác dụng SAU
  /// khi trang gốc đã tải xong, để không chặn nhầm redirect ban đầu của site.
  bool _isAllowedHost(String host) {
    final locked = _lockedHost;
    if (locked == null || locked.isEmpty) return true;
    return host == locked || host.endsWith('.$locked');
  }

  // ── Shared WebView configuration ────────────────────────────────────────────

  /// Mobile Chrome UA cho trang thông thường.
  /// TikTok yêu cầu iOS Safari UA để hiển thị đúng mobile layout.
  String get webViewUserAgent => isTikTok
      ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
            'AppleWebKit/605.1.15 (KHTML, like Gecko) '
            'Version/17.0 Mobile/15E148 Safari/604.1'
      : 'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/124.0.0.0 Mobile Safari/537.36';

  /// Cấu hình InAppWebView dùng chung cho cả inline lẫn expanded mode.
  InAppWebViewSettings get webViewSettings => InAppWebViewSettings(
    userAgent: webViewUserAgent,

    // ── JavaScript & Storage ─────────────────────────────────────────────
    javaScriptEnabled: true,
    domStorageEnabled: true, // localStorage / sessionStorage cho SPA
    databaseEnabled: true,

    // ── Cache ────────────────────────────────────────────────────────────
    cacheEnabled: true,
    // Dùng cache trước, chỉ fetch mạng khi không có — giảm latency.
    cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,

    // ── Rendering (Android) ──────────────────────────────────────────────
    // Dùng HybridComposition để giảm lỗi/log BLASTBufferQueue trên một số máy.
    useHybridComposition: true,
    transparentBackground: true,

    // ── Media ────────────────────────────────────────────────────────────
    mediaPlaybackRequiresUserGesture: false, // cho phép autoplay video
    allowsInlineMediaPlayback: true, // iOS: video inline thay vì fullscreen
    // ── Scroll / UX ──────────────────────────────────────────────────────
    overScrollMode: OverScrollMode.NEVER, // tắt bounce cuộn quá đầu/cuối
    verticalScrollBarEnabled: false,
    horizontalScrollBarEnabled: false,
    supportZoom: false, // tắt pinch-to-zoom (link preview không cần)
    // ── Misc ─────────────────────────────────────────────────────────────
    disableDefaultErrorPage: true, // tự xử lý trang lỗi nếu cần
    safeBrowsingEnabled: true, // bảo vệ người dùng khỏi trang độc hại
    // Bật để shouldInterceptRequest được gọi — chặn quảng cáo ở tầng network.
    useShouldInterceptRequest: true,
    // Giữ true (mặc định): nhiều trang phim/streaming tự mở window.open()
    // không qua cử chỉ người dùng để nhúng player thật, không chỉ ads dùng
    // cách này. Việc lọc ads/popup giờ nằm ở onCreateWindow (chỉ huỷ khi
    // đích đến là domain quảng cáo) — set false ở đây sẽ chặn cứng ở tầng
    // native trước khi onCreateWindow kịp phân biệt, chặn nhầm cả nội dung.
    javaScriptCanOpenWindowsAutomatically: true,
  );

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
    hasLoadError.value = false;
    currentUrl.value = newUrl ?? '';
    _updateNavState();
  }

  void onPageFinished(String? newUrl) {
    isWebLoading.value = false;
    currentUrl.value = newUrl ?? '';
    _updateNavState();

    // Khoá domain vào đúng lúc trang gốc (hoặc trang đã redirect tới) tải
    // xong — từ giờ mọi điều hướng sang domain khác (ads, shopee, link rác...)
    // sẽ bị chặn ở shouldOverrideUrlLoading/onCreateWindow bên dưới. Cập nhật
    // lại mỗi lần tải xong (không chỉ lần đầu) để tự "đi theo" nếu người dùng
    // điều hướng hợp lệ trong cùng site (đổi tập phim...).
    final finishedHost = Uri.tryParse(newUrl ?? '')?.host ?? '';
    if (finishedHost.isNotEmpty) _lockedHost = finishedHost;

    // 1. Tiêm JS chặn quảng cáo chung cho mọi trang
    webViewController?.evaluateJavascript(source: _adBlockerJS);

    // 2. Tiêm JS tối ưu riêng cho TikTok
    if (newUrl != null && newUrl.contains("tiktok.com")) {
      webViewController?.evaluateJavascript(source: _tiktokJS);
    }
  }

  /// Trang chính tải lỗi (mất kết nối, SSL handshake fail, site chặn...).
  /// Chỉ set cờ khi lỗi thuộc về main frame — lỗi của 1 sub-resource lẻ
  /// (ảnh, script quảng cáo bị chặn) không nên làm cả trang báo lỗi.
  void onReceivedError(WebResourceRequest request) {
    if (request.isForMainFrame ?? true) {
      isWebLoading.value = false;
      hasLoadError.value = true;
    }
  }

  Future<NavigationActionPolicy> shouldOverrideUrlLoading(NavigationAction navigationAction) async {
    final uri = navigationAction.request.url;
    if (uri == null) return NavigationActionPolicy.ALLOW;

    if (_isAdHost(uri.host)) return NavigationActionPolicy.CANCEL;

    if (!uri.scheme.startsWith('http')) return NavigationActionPolicy.CANCEL;

    if (uri.host.contains('tiktok.com') && uri.path.contains('download')) {
      return NavigationActionPolicy.CANCEL;
    }

    // Khoá điều hướng trong đúng domain của trang — chặn kiểu quảng cáo phổ
    // biến trên site phim/đọc truyện: bấm bất kỳ đâu trên trang cũng bị đẩy
    // sang shopee/link rác/domain lạ, dù domain đó không nằm trong danh sách
    // ads cố định ở trên.
    if (!_isAllowedHost(uri.host)) return NavigationActionPolicy.CANCEL;

    return NavigationActionPolicy.ALLOW;
  }

  /// Chặn từng sub-resource (ảnh/script/iframe quảng cáo, không phải chỉ
  /// điều hướng trang) trước khi WebView tải — nguồn "lag" chính trên các
  /// trang đọc truyện/tin tức thường là hàng chục request quảng cáo/tracker
  /// chạy ngầm mỗi lần cuộn trang, không phải nội dung chính.
  ///
  /// Không bao giờ chặn request của chính main frame (kể cả khi nó bị
  /// redirect qua domain trung gian) — nhiều site phim/streaming (vd.
  /// motchilltv.ltd) tự chuyển hướng qua nhiều domain trước khi tới trang
  /// thật; lỡ chặn nhầm 1 bước redirect ở đây thì cả trang không tải được
  /// gì, chỉ còn nền đen — trong khi mục tiêu ban đầu chỉ là chặn ads/tracker
  /// phụ, không phải nội dung chính.
  Future<WebResourceResponse?> shouldInterceptRequest(WebResourceRequest request) async {
    if (request.isForMainFrame ?? true) return null;
    final host = request.url.host;
    if (_isAdHost(host)) {
      return WebResourceResponse(contentType: 'text/plain', data: Uint8List(0));
    }
    return null;
  }

  /// Nhiều trang phim/streaming dùng chính window.open()/target=_blank để
  /// nhúng nội dung/player thật (không chỉ ads dùng cách này) — chặn tuyệt
  /// đối mọi window mới trước đây vô tình chặn luôn nội dung chính, để lại
  /// mỗi nền đen rỗng. Giờ chỉ huỷ khi đích đến là domain quảng cáo; còn lại
  /// load ngay trong webview hiện tại (không tạo cửa sổ mới) để nội dung vẫn
  /// hiển thị được.
  Future<bool> onCreateWindow(
    InAppWebViewController controller,
    CreateWindowAction createWindowAction,
  ) async {
    final uri = createWindowAction.request.url;
    if (uri == null) return false;
    if (_isAdHost(uri.host)) return false;
    // Cùng lý do domain lock ở shouldOverrideUrlLoading: popup ra khỏi
    // domain đang khoá gần như chắc chắn là ads/redirect rác, kể cả khi
    // domain đó không có trong danh sách ads cố định.
    if (!_isAllowedHost(uri.host)) return false;
    await controller.loadUrl(urlRequest: URLRequest(url: uri));
    return true;
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
    hasLoadError.value = false;
    _lockedHost = null;
    webViewController = null;
  }

  void copyUrl() {
    if (url.isEmpty) return;
    Clipboard.setData(ClipboardData(text: url));
    AppToast.showToast('link_copied'.tr, Icons.copy_rounded, color: Colors.green);
  }

  void openInApp() {
    if (url.isNotEmpty) Utils.lanchUrl(url);
  }

  void openInMaps() {
    if (address.isEmpty) return;
    final query = Uri.encodeComponent(address);
    Utils.lanchUrl('https://www.google.com/maps/search/?api=1&query=$query');
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
  String get _adBlockerJS =>
      '''
    (function() {
      // Chỉ chặn window.open() tới domain quảng cáo — nhiều trang (đặc biệt
      // site phim/streaming) dùng chính window.open để nhúng nội dung/player
      // thật, chặn vô điều kiện sẽ chặn luôn nội dung chính. Với URL hợp lệ,
      // điều hướng ngay trong tab hiện tại (như target=_self) thay vì mở tab
      // mới, để tránh popup rác mà vẫn không chặn nội dung thật.
      const _adDomains = $_adDomainsJsArray;
      function _isAdUrl(u) {
        if (!u) return false;
        return _adDomains.some(function(d) { return u.indexOf(d) !== -1; });
      }
      const _origOpen = window.open;
      window.open = function(url) {
        if (_isAdUrl(url)) return null;
        if (url) {
          window.location.href = url;
          return window;
        }
        return _origOpen ? _origOpen.apply(window, arguments) : null;
      };

      const adSelectors = [
        '.adsbygoogle', 'ins.adsbygoogle', '[id^="google_ads_"]',
        'iframe[src*="doubleclick.net"]', '.ad-box', '.ad-container', '.ad-unit',
        '[class*="popup-ads"]', '[id*="popup-ad"]', '.ads-container', '[class^="ads-"]'
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

    // Theo dõi thay đổi DOM thay vì polling mỗi giây để tránh chạy liên tục.
    const observer = new MutationObserver(() => hideAppPrompts());
    observer.observe(document.documentElement, { childList: true, subtree: true });

    // Dọn observer sau 15s để không giữ task chạy mãi.
    setTimeout(() => observer.disconnect(), 15000);
  ''';

  @override
  void onClose() {
    webViewController = null;
    super.onClose();
  }
}
