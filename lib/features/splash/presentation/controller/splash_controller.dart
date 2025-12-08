import 'package:get/get.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';
import 'package:keep_link/core/service/biometric_service.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/features/link/presentation/page/add_link_page.dart';
import 'package:keep_link/features/link/presentation/page/link_collection_page.dart';

class SplashArg {
  final String? deepLinkText;
  SplashArg({this.deepLinkText});
}

class SplashController extends GetxController {
  final isSecurityEnabled = false.obs;
  final isFingerprintEnabled = false.obs;
  final needPinVerify = false.obs;

  @override
  void onInit() {
    super.onInit();
    isSecurityEnabled.value = AppGetStorage.isSecurityEnabled();
    isFingerprintEnabled.value = AppGetStorage.isFingerprintEnabled();
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // Delay nhẹ để hiển thị splash đẹp hơn
    await Future.delayed(const Duration(milliseconds: 300));
    // ---------- 1. Deep Link ----------
    final shared = DeepLinkService.sharedText;
    if (shared != null) {
      Get.offAllNamed(AddLinkPage.routeName, arguments: SplashArg(deepLinkText: shared));
      return;
    }

    // ---------- 2. Chưa bật security ----------
    if (!isSecurityEnabled.value) {
      goToHome();
      return;
    }
    needPinVerify.value = true;
  }

  void verifyFinger() async {
    if (isFingerprintEnabled.value) {
      final ok = await BiometricService.authenticate();
      if (ok) {
        goToHome();
        return;
      }
    }
  }

  void goToHome() {
    Get.offAllNamed(LinkCollectionPage.routeName);
  }
}
