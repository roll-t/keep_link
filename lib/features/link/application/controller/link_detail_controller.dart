import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/link/application/controller/link_collection_controller.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/presentation/link_add/page/add_link_page.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LinkDetailController extends GetxController {
  final LinkModel link;
  LinkDetailController({required this.link});

  final isPlayingVideo = false.obs;
  WebViewController? webViewController;

  String get imageUrl => link.metaDataModel?.imageUrl ?? '';
  String get url => link.metaDataModel?.url ?? '';
  String get title => link.metaDataModel?.title ?? link.name ?? '';
  String get description => link.metaDataModel?.description ?? '';

  void playVideo() {
    if (url.isEmpty) return;
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(url));
    isPlayingVideo.value = true;
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
    Get.back();
    Get.find<LinkCollectionController>().onDeleteLink(link.id);
  }
}
