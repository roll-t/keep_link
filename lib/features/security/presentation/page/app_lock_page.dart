import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/assets/app_images.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/services/platform/biometric_service.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/security/application/di/pin_verify_binding.dart';
import 'package:keep_link/features/security/presentation/widget/pin_verify_form.dart';

/// Màn hình khoá hiển thị lại khi app quay về foreground sau khi đã bị đưa xuống
/// nền (Home, chuyển app khác, khoá màn hình...) trong lúc "Bảo mật ứng dụng" đang bật.
///
/// Trước khi có màn này, app chỉ kiểm tra PIN/vân tay 1 lần lúc khởi động (SplashPage) —
/// nghĩa là mở lại app từ background KHÔNG yêu cầu xác thực lại, ai cầm được máy trong
/// lúc app vẫn đang chạy nền là vào thẳng được toàn bộ dữ liệu. Không thể pop bằng nút back.
class AppLockPage extends StatefulWidget {
  const AppLockPage({super.key});

  @override
  State<AppLockPage> createState() => _AppLockPageState();
}

class _AppLockPageState extends State<AppLockPage> {
  bool _fingerprintEnabled = false;
  bool _biometricInFlight = false;

  @override
  void initState() {
    super.initState();
    // Đảm bảo PinVerifyController luôn mới hoàn toàn cho lần khoá này
    // (không kế thừa state cũ từ 1 luồng PIN khác đang/đã chạy trước đó).
    PinVerifyBinding().dependencies();
    _fingerprintEnabled = AppGetStorage.isFingerprintEnabled();
    if (_fingerprintEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  Future<void> _tryBiometric() async {
    if (_biometricInFlight) return;
    _biometricInFlight = true;
    try {
      if (!await BiometricService.canCheck()) return;
      final ok = await BiometricService.authenticate();
      if (ok && mounted) Get.back();
    } finally {
      _biometricInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage(AppImages.iBgSplash.path), fit: BoxFit.cover),
        ),
        child: GestureDetector(
          onTap: Utils.dimissKeyboard,
          child: Scaffold(
            backgroundColor: AppColors.transparent,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 28,
                children: [
                  AppImages.iLogo.show(size: Get.width * .35),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.d700,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    width: Get.width * .8,
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PinVerifyForm(
                          width: Get.width * .8,
                          margin: EdgeInsets.zero,
                          background: AppColors.d700,
                          onCompleted: () {
                            if (mounted) Get.back();
                          },
                        ),
                        if (_fingerprintEnabled) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: TextWidget(text: "Or".tr),
                          ),
                          AppVectors.icFinger.show(size: 60, onTap: _tryBiometric),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
