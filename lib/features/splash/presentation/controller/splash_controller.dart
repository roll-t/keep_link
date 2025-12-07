import 'package:get/get.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/features/link/presentation/page/add_link_page.dart';
import 'package:keep_link/features/link/presentation/page/link_collection_page.dart';

class SplashArg {
  final String? deepLinkText;
  SplashArg({this.deepLinkText});
}

class SplashController extends GetxController {
  final isSecurityEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load từ GetStorage
    isSecurityEnabled.value = AppGetStorage.isSecurityEnabled();
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    _handleNavigation();
  }

  void _handleNavigation() {
    // 1. Deep link → chuyển thẳng vào AddLinkPage
    final shared = DeepLinkService.sharedText;
    if (shared != null) {
      Get.offAllNamed(AddLinkPage.routeName, arguments: SplashArg(deepLinkText: shared));
      return;
    }

    // 2. Nếu có security → hiển thị form nhập PIN
    if (isSecurityEnabled.value) {
      return; // Giữ lại ở SplashPage để nhập PIN
    }

    // 3. Không security → vào home
    goToHome();
  }

  void goToHome() {
    Get.offAllNamed(LinkCollectionPage.routeName);
  }
}
