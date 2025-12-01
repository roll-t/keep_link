import 'package:get/get.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/features/link/presentation/page/add_link_page.dart';
import 'package:keep_link/features/link/presentation/page/link_collection_page.dart';

class SplashArg {
  String? deepLinkText;
  SplashArg({this.deepLinkText});
}

class SplashController extends GetxController {
  SplashController();
  @override
  Future<void> onReady() async {
    super.onReady();
    if (DeepLinkService.sharedText != null) {
      Get.offAllNamed(
        AddLinkPage.routeName,
        arguments: SplashArg(deepLinkText: DeepLinkService.sharedText),
      );
      return;
    }
    Get.offAllNamed(LinkCollectionPage.routeName);
  }
}
