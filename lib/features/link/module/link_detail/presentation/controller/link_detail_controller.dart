import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/data/repositories/link_repository.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/application/model/link_platform.dart';
import 'package:keep_link/features/link/application/model/link_type.dart';
import 'package:keep_link/features/link/module/link_add/presentation/page/add_link_page.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/link_collection_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkDetailArguments {
  const LinkDetailArguments({required this.link, this.readOnly = false});

  final LinkModel link;
  final bool readOnly;
}

class LinkDetailController extends GetxController {
  final LinkModel link;
  final bool readOnly;

  LinkDetailController({required this.link, this.readOnly = false});

  final isPlayingVideo = false.obs;
  final isExpanded = false.obs;
  final canGoBack = false.obs;
  final canGoForward = false.obs;
  final currentUrl = ''.obs;
  final isWebLoading = false.obs;
  final webLoadProgress = 0.obs;
  final hasWebContent = false.obs;
  final webViewGeneration = 0.obs;
  // Trang chính (không phải sub-resource) tải lỗi — vd. site chặn kết nối,
  // SSL handshake fail... Không có cờ này thì người dùng chỉ thấy màn hình
  // đen im lìm không rõ đang tải hay đã hỏng, không biết phải làm gì tiếp.
  final hasLoadError = false.obs;
  InAppWebViewController? webViewController;

  late final String url = _normalizeWebUrl(link.metaDataModel?.url);
  late final LinkType linkType = LinkTypeDetector.detect(url);
  late final LinkPlatform linkPlatform = LinkPlatformDetector.detect(url);

  /// Chế độ mở web: Công khai (false) hoặc Ẩn danh (true)
  final isIncognito = AppGetStorage.isIncognitoMode().obs;

  void toggleIncognito(bool value) {
    isIncognito.value = value;
    AppGetStorage.setIncognitoMode(value);
  }

  bool get isVideo => linkType == LinkType.video;
  String get imageUrl => link.metaDataModel?.imageUrl ?? '';
  String get title => link.metaDataModel?.title ?? link.name ?? '';
  String get description => link.metaDataModel?.description ?? '';
  bool get isTikTok => url.contains("tiktok.com");
  String get address => link.metaDataModel?.address ?? '';
  bool get hasLocation => address.isNotEmpty;

  // ── Category management ──────────────────────────────────────────────────
  late final currentCategoryId = Rx<String?>(link.categoryId);

  CategoryModel? get currentCategory {
    final cid = currentCategoryId.value;
    if (cid == null || cid.isEmpty || cid == 'all') return null;
    return AppCache.categories.firstWhereOrNull((c) => c.id == cid);
  }

  void showReadOnlyMessage() => _showReadOnlyMessage();

  Future<void> changeCategory(String? newCategoryId) async {
    if (readOnly) {
      _showReadOnlyMessage();
      return;
    }
    final normalizedId =
        (newCategoryId == null || newCategoryId.isEmpty || newCategoryId == 'all')
            ? null
            : newCategoryId;

    if (currentCategoryId.value == normalizedId) return;

    final updatedLink = LinkModel(
      id: link.id,
      name: link.name,
      image: link.image,
      metaDataModel: link.metaDataModel,
      categoryId: normalizedId,
      createdAt: link.createdAt,
      updatedAt: DateTime.now(),
    );

    await LinkRepository.update(updatedLink);
    currentCategoryId.value = normalizedId;

    if (Get.isRegistered<LinkCollectionController>()) {
      Get.find<LinkCollectionController>().onRefreshData();
    }

    if (normalizedId != null) {
      final cat =
          AppCache.categories.firstWhereOrNull((c) => c.id == normalizedId);
      final catName = cat?.name ?? 'Category'.tr;
      AppToast.showToast(
        'category_changed'.trParams({'name': catName}),
        Icons.check_circle_rounded,
        color: AppColors.success,
      );
    } else {
      AppToast.showToast(
        'category_removed'.tr,
        Icons.check_circle_rounded,
        color: AppColors.success,
      );
    }
  }

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

  static bool _isAdHost(String host) =>
      _adDomains.any((domain) => host.contains(domain));

  static String get _adDomainsJsArray =>
      '[${_adDomains.map((d) => "'$d'").join(',')}]';

  bool _isLaunchingFallback = false;

  // ── Shared WebView configuration ────────────────────────────────────────────

  /// Cấu hình InAppWebView dùng chung cho cả inline lẫn expanded mode.
  InAppWebViewSettings get webViewSettings => InAppWebViewSettings(
    // ── JavaScript & Storage ─────────────────────────────────────────────
    javaScriptEnabled: true,
    domStorageEnabled: true, // localStorage / sessionStorage cho SPA
    databaseEnabled: true,
    thirdPartyCookiesEnabled: true,

    // ── Cache ────────────────────────────────────────────────────────────
    cacheEnabled: !isIncognito.value,
    clearCache: isIncognito.value,
    incognito: isIncognito.value,
    // LOAD_DEFAULT vẫn tận dụng HTTP cache nhưng revalidate khi cần. Chế độ
    // cache-first trước đây giữ lại redirect/trang lỗi cũ quá lâu.
    cacheMode: isIncognito.value ? CacheMode.LOAD_NO_CACHE : CacheMode.LOAD_DEFAULT,

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
    mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
    useShouldOverrideUrlLoading: true,
    supportMultipleWindows: true,
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
    if (url.isEmpty) {
      _showOpenError();
      return;
    }
    _prepareInitialWebLoad();
    isExpanded.value = true;
    isPlayingVideo.value = true;
  }

  void playVideo() {
    if (url.isEmpty) {
      _showOpenError();
      return;
    }
    _prepareInitialWebLoad();
    isExpanded.value = true;
    isPlayingVideo.value = true;
  }

  void _prepareInitialWebLoad() {
    currentUrl.value = url;
    webLoadProgress.value = 0;
    hasWebContent.value = false;
    hasLoadError.value = false;
    isWebLoading.value = true;
  }

  // CÁC CALLBACK ĐƯỢC DỜI TỪ _initWebViewController ĐỂ UI GỌI
  void onPageStarted(String? newUrl) {
    isWebLoading.value = true;
    webLoadProgress.value = 0;
    hasLoadError.value = false;
    currentUrl.value = (newUrl == null || newUrl.isEmpty) ? url : newUrl;
    _updateNavState();
  }

  void onProgressChanged(int progress) {
    webLoadProgress.value = progress.clamp(0, 100);
  }

  void onPageFinished(String? newUrl) {
    webLoadProgress.value = 100;
    isWebLoading.value = false;
    hasWebContent.value = true;
    currentUrl.value = newUrl ?? '';
    _updateNavState();

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
    if (request.isForMainFrame == true) {
      isWebLoading.value = false;
      webLoadProgress.value = 0;
      hasLoadError.value = true;
    }
  }

  void onHistoryUpdated(String? newUrl) {
    if (newUrl == null || newUrl.isEmpty) return;
    currentUrl.value = newUrl;
    _updateNavState();
  }

  void onReceivedHttpError(
    WebResourceRequest request,
    WebResourceResponse response,
  ) {
    if (request.isForMainFrame == true && (response.statusCode ?? 0) >= 400) {
      isWebLoading.value = false;
      webLoadProgress.value = 0;
      hasLoadError.value = true;
    }
  }

  void onRenderProcessGone() {
    isWebLoading.value = false;
    webLoadProgress.value = 0;
    hasWebContent.value = false;
    hasLoadError.value = true;
    webViewController = null;
    webViewGeneration.value++;
  }

  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
    NavigationAction navigationAction,
  ) async {
    final uri = navigationAction.request.url;
    if (uri == null) return NavigationActionPolicy.ALLOW;

    if (_isAdHost(uri.host)) return NavigationActionPolicy.CANCEL;

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      // App/deep-link chỉ được phép bật khi phát sinh từ thao tác thật của
      // người dùng; redirect tự động không được tự ý mở ứng dụng khác.
      if (navigationAction.hasGesture == true) {
        await _launchExternalScheme(uri);
      }
      return NavigationActionPolicy.CANCEL;
    }

    if (uri.host.contains('tiktok.com') && uri.path.contains('download')) {
      return NavigationActionPolicy.CANCEL;
    }

    // Không khoá theo domain: đăng nhập, short-link, CDN và payment thường
    // redirect qua domain hợp lệ khác. Khoá cũ là nguyên nhân nhiều link bị
    // đứng im dù trang đích hoàn toàn hợp lệ.
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
  Future<WebResourceResponse?> shouldInterceptRequest(
    WebResourceRequest request,
  ) async {
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
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      if (createWindowAction.hasGesture == true) {
        await _launchExternalScheme(uri);
      }
      return false;
    }
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

  Future<void> webReload() async {
    hasLoadError.value = false;
    isWebLoading.value = true;
    webLoadProgress.value = 0;
    final controller = webViewController;
    if (controller == null) {
      webViewGeneration.value++;
      return;
    }
    await controller.reload();
  }

  Future<void> webGoHome() async {
    if (url.isNotEmpty) {
      hasLoadError.value = false;
      isWebLoading.value = true;
      webLoadProgress.value = 0;
      await webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(url)),
      );
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
    webLoadProgress.value = 0;
    hasWebContent.value = false;
    hasLoadError.value = false;
    webViewController = null;
  }

  void copyUrl() {
    if (url.isEmpty) return;
    Clipboard.setData(ClipboardData(text: url));
    AppToast.showToast(
      'link_copied'.tr,
      Icons.copy_rounded,
      color: AppColors.success,
    );
  }

  Future<void> openInApp() async => openDestination();

  Future<void> openDestination() async {
    if (url.isEmpty || _isLaunchingFallback) return;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showOpenError();
      return;
    }

    _isLaunchingFallback = true;
    try {
      var opened = false;
      if (linkPlatform.isApp) {
        // Đối với ứng dụng (YouTube, TikTok, Facebook, Instagram,...):
        // Thử mở bằng App ngoài native đã cài trên máy trước.
        try {
          opened = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        } catch (error) {
          debugPrint('Open non-browser app error: $error');
        }

        if (!opened) {
          try {
            opened = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
          } catch (error) {
            debugPrint('Open external app error: $error');
          }
        }
      } else {
        // Đối với website thông thường:
        if (isIncognito.value) {
          // Chế độ ẩn danh (Incognito): Không lưu lịch sử, không lưu cookie/session
          try {
            final browser = InAppBrowser();
            await browser.openUrlRequest(
              urlRequest: URLRequest(url: WebUri(url)),
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
          // Chế độ công khai / bình thường: mở Custom Tabs / InAppBrowserView
          try {
            opened = await launchUrl(
              uri,
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
          opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (error) {
          debugPrint('Open fallback external browser error: $error');
        }
      }

      if (!opened) _showOpenError();
    } finally {
      _isLaunchingFallback = false;
    }
  }

  Future<void> _launchExternalScheme(WebUri webUri) async {
    final raw = webUri.toString();
    final uri = Uri.tryParse(raw);
    if (uri == null || _isUnsafeExternalScheme(uri.scheme)) return;

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || uri.scheme.toLowerCase() != 'intent') return;
    } catch (error) {
      debugPrint('Open external scheme error: $error');
    }

    // intent:// thường kèm URL web dự phòng. Nếu thiết bị không có ứng dụng
    // đích, tải fallback ngay trong WebView thay vì bỏ thao tác của người dùng.
    final match = RegExp(r'S\.browser_fallback_url=([^;]+)').firstMatch(raw);
    if (match == null) return;
    final fallback = Uri.tryParse(Uri.decodeComponent(match.group(1)!));
    if (fallback == null ||
        (fallback.scheme != 'http' && fallback.scheme != 'https')) {
      return;
    }
    await webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(fallback.toString())),
    );
  }

  static bool _isUnsafeExternalScheme(String scheme) {
    return const {
      '',
      'file',
      'content',
      'javascript',
      'data',
      'about',
      'blob',
    }.contains(scheme.toLowerCase());
  }

  static String _normalizeWebUrl(String? rawUrl) {
    var value = rawUrl?.trim() ?? '';
    if (value.isEmpty) return '';
    if (!value.contains('://')) value = 'https://$value';

    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return '';
    }
    return uri.toString();
  }

  void _showOpenError() {
    AppToast.showToast(
      'Unable to open URL'.tr,
      Icons.error_outline_rounded,
      color: AppColors.danger,
    );
  }

  void openInMaps() {
    if (address.isEmpty) return;
    final query = Uri.encodeComponent(address);
    Utils.lanchUrl('https://www.google.com/maps/search/?api=1&query=$query');
  }

  void goToEdit() {
    if (readOnly) {
      _showReadOnlyMessage();
      return;
    }
    Get.back();
    Get.toNamed(AddLinkPage.routeName, arguments: link)?.then((success) {
      if (success == true) {
        Get.find<LinkCollectionController>().onRefreshData();
      }
    });
  }

  void deleteLink() {
    if (readOnly) {
      _showReadOnlyMessage();
      return;
    }
    Get.find<LinkCollectionController>().onDeleteLink(link.id);
  }

  void _showReadOnlyMessage() {
    AppToast.showToast(
      'shared_link_read_only'.tr,
      Icons.visibility_rounded,
      color: AppColors.infoMuted,
    );
  }

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
