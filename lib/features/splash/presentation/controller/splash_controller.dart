import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/features/link/presentation/page/add_link_page.dart';
import 'package:keep_link/features/link/presentation/page/link_collection_page.dart';
import 'package:keep_link/features/setting/application/di/pin_verify_binding.dart';
import 'package:keep_link/features/setting/presentation/widget/pin_verify_form.dart';

class SplashArg {
  String? deepLinkText;
  SplashArg({this.deepLinkText});
}

class SplashController extends GetxController {
  @override
  Future<void> onReady() async {
    super.onReady();

    // =======================================================
    // 1. Deep link → mở AddLinkPage trực tiếp
    // =======================================================
    if (DeepLinkService.sharedText != null) {
      Get.offAllNamed(
        AddLinkPage.routeName,
        arguments: SplashArg(deepLinkText: DeepLinkService.sharedText),
      );
      return;
    }

    // =======================================================
    // 2. Kiểm tra security + PIN
    // =======================================================
    final bool isSecurityEnabled = AppGetStorage.isSecurityEnabled();
    final String? savedPin = AppGetStorage.getPin();

    // if (isSecurityEnabled && (savedPin == null || savedPin.isEmpty)) {
    //   Get.toNamed("/PinVerifyPage");
    //   return;
    // }

    // Nếu bật security + có PIN → yêu cầu nhập PIN
    print(isSecurityEnabled);
    if (isSecurityEnabled) {
      _showPinDialog();
      return;
    }

    // =======================================================
    // 3. Không security → vào home
    // =======================================================
    _goToHome();
  }

  // =======================================================
  // SHOW PIN VERIFY DIALOG
  // =======================================================
  void _showPinDialog() {
    DialogUtils.show(
      Material(
        color: AppColors.transparent,
        child: Center(
          child: PinVerifyForm(
            fromType: FromType.confirm,
            onCompleted: () {
              Get.back(); // đóng dialog
              _goToHome(); // vào home
            },
          ),
        ),
      ),
      binding: PinVerifyBinding(),
      barrierDismissible: false, // không cho bấm ra ngoài
    );
  }

  // =======================================================
  // GO TO HOME
  // =======================================================
  void _goToHome() {
    Get.offAllNamed(LinkCollectionPage.routeName);
  }
}
