import 'package:flutter/foundation.dart';
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

  late final LinkType linkType = LinkTypeDetector.detect(url);

  // Getter tiện ích
  bool get isVideo => linkType == LinkType.video;

  String get imageUrl => link.metaDataModel?.imageUrl ?? '';
  String get url => link.metaDataModel?.url ?? '';
  String get title => link.metaDataModel?.title ?? link.name ?? '';
  String get description => link.metaDataModel?.description ?? '';

  void openWebView() {
    if (url.isEmpty) return;
    _initWebViewController();
    isPlayingVideo.value = true;
  }

  void playVideo() {
    if (url.isEmpty) return;
    _initWebViewController();
    isPlayingVideo.value = true;
  }

  void _initWebViewController() {
    if (webViewController != null) return;

    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) async {
            isWebLoading.value = true;
            currentUrl.value = url;
            await _updateNavState();
          },
          onPageFinished: (url) async {
            isWebLoading.value = false;
            currentUrl.value = url;
            await _updateNavState();
            await webViewController?.runJavaScript('''
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.getElementsByTagName('head')[0].appendChild(meta);
            
            document.body.style.margin = '0';
            document.body.style.padding = '0';
            document.body.style.width = '100%';
          ''');
          },
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();

            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              debugPrint("Đã chặn mở app ngoại luồng: $url");
              return NavigationDecision.prevent;
            }

            // Chặn chuyển hướng văng ra App Store hoặc Google Play
            if (url.contains('play.google.com') || url.contains('apps.apple.com')) {
              debugPrint("Đã chặn văng ra chợ ứng dụng: $url");
              return NavigationDecision.prevent;
            }

            // Cho phép các trang web bình thường duyệt tiếp
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  Future<void> _updateNavState() async {
    canGoBack.value = await webViewController?.canGoBack() ?? false;
    canGoForward.value = await webViewController?.canGoForward() ?? false;
  }

  Future<void> webReload() async {
    await webViewController?.reload();
  }

  // Quay về trang gốc (URL ban đầu của link)
  Future<void> webGoHome() async {
    await webViewController?.loadRequest(Uri.parse(url));
  }

  void toggleExpand() => isExpanded.toggle();

  void closeWebView() {
    isPlayingVideo.value = false;
    isExpanded.value = false;
    canGoBack.value = false;
    canGoForward.value = false;
    currentUrl.value = '';
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
      if (success is bool && success) {
        Get.find<LinkCollectionController>().onRefreshData();
      }
    });
  }

  void deleteLink() {
    Get.find<LinkCollectionController>().onDeleteLink(link.id);
  }
}
