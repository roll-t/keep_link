import 'dart:async';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/services/platform/biometric_service.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/presentation/controller/custom_popup_controller.dart';
import 'package:keep_link/features/security/presentation/page/pin_verify_page.dart';
import 'package:keep_link/features/security/presentation/widget/pin_verify_form.dart';

class SecurityMethodController extends GetxController {
  final isAppSecurityEnabled = false.obs;
  final isFingerprintEnabled = false.obs;
  final isCategorySecurityEnabled = false.obs;
  final isVerified = false.obs;

  // Chặn double-tap khi 1 thao tác bật/tắt (có thể phải chờ verify PIN/vân tay) đang xử lý dở.
  final isBusy = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  @override
  void onReady() {
    super.onReady();
    _initialSecurityCheck();
  }

  void _loadSettings() {
    isAppSecurityEnabled.value = AppGetStorage.isSecurityEnabled();
    isFingerprintEnabled.value = AppGetStorage.isFingerprintEnabled();
    isCategorySecurityEnabled.value = AppGetStorage.isCategorySecurity();
  }

  // ─── KIỂM TRA BẢO MẬT KHI VÀO MÀN HÌNH SETTINGS ───────────────────────────

  Future<void> _initialSecurityCheck() async {
    if (!isAppSecurityEnabled.value && !isCategorySecurityEnabled.value) {
      isVerified.value = true;
      return;
    }

    await Future.delayed(const Duration(milliseconds: 200));

    if (await _tryBiometric()) {
      isVerified.value = true;
      return;
    }

    _showPinDialog(
      onSuccess: () => isVerified.value = true,
      onDismiss: () {
        if (!isVerified.value) Get.back();
      },
    );
  }

  Future<bool> _tryBiometric() async {
    if (!isFingerprintEnabled.value) return false;
    if (!await BiometricService.canCheck()) return false;
    return BiometricService.authenticate();
  }

  void _showPinDialog({required VoidCallback onSuccess, VoidCallback? onDismiss}) {
    DialogUtils.showPinDialog(
      onCompleted: () {
        if (Get.isDialogOpen ?? false) Get.back();
        onSuccess();
      },
      onDismiss: onDismiss,
    );
  }

  Future<void> _verifyThenRun(Future<void> Function() onSuccess) async {
    if (await _tryBiometric()) {
      await onSuccess();
      return;
    }

    _showPinDialog(
      onSuccess: () async {
        await onSuccess();
      },
    );
  }

  Future<bool> _ensurePinExists() async {
    if (AppGetStorage.hasPin()) return true;

    final newPin = await Get.toNamed(PinVerifyPage.routeName);
    return newPin != null;
  }

  // ─── 1. BẬT / TẮT BẢO MẬT ỨNG DỤNG ────────────────────────────────────────

  Future<void> toggleAppSecurity() async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      if (!isAppSecurityEnabled.value) {
        final success = await _ensurePinExists();
        if (!success) return;

        isAppSecurityEnabled.value = true;
        AppGetStorage.setSecurityEnabled(true);
        Utils.showToast('Đã bật bảo mật ứng dụng');
      } else {
        await _verifyThenRun(() async {
          isAppSecurityEnabled.value = false;
          AppGetStorage.setSecurityEnabled(false);

          // Tắt vân tay kèm theo nếu đang bật
          if (isFingerprintEnabled.value) {
            isFingerprintEnabled.value = false;
            AppGetStorage.setFingerprintEnabled(false);
          }

          Utils.showToast('Đã tắt bảo mật ứng dụng');
        });
      }
    } finally {
      isBusy.value = false;
    }
  }

  // ─── 2. BẬT / TẮT BẢO MẬT DANH MỤC ────────────────────────────────────────

  Future<void> toggleCategorySecurity() async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      if (!isCategorySecurityEnabled.value) {
        final success = await _ensurePinExists();
        if (!success) return;

        isCategorySecurityEnabled.value = true;
        AppGetStorage.setCategorySecurity(true);
        Utils.showToast('Đã bật bảo mật danh mục');
        _refreshCustomPopup();
      } else {
        await _verifyThenRun(() async {
          isCategorySecurityEnabled.value = false;
          AppGetStorage.setCategorySecurity(false);
          Utils.showToast('Đã tắt bảo mật danh mục');
          _refreshCustomPopup();
        });
      }
    } finally {
      isBusy.value = false;
    }
  }

  void _refreshCustomPopup() {
    if (!Get.isRegistered<CustomPopupController>()) return;
    Get.find<CustomPopupController>().isEnableSecurity.value = isCategorySecurityEnabled.value;
  }

  // ─── 3. BẬT / TẮT VÂN TAY ──────────────────────────────────────────────────

  Future<void> toggleFingerprint() async {
    if (isBusy.value) return;

    if (!isAppSecurityEnabled.value) {
      Utils.showToast('Vui lòng bật bảo mật ứng dụng trước');
      return;
    }

    if (!AppGetStorage.hasPin()) {
      Utils.showToast('Vui lòng thiết lập mã PIN trước');
      return;
    }

    isBusy.value = true;
    try {
      // Tắt vân tay — yêu cầu xác thực lại để nhất quán với việc tắt các bảo mật khác,
      // tránh ai đó cầm máy lúc app đang mở tắt luôn lớp bảo vệ mà không cần xác nhận gì.
      if (isFingerprintEnabled.value) {
        await _verifyThenRun(() async {
          isFingerprintEnabled.value = false;
          AppGetStorage.setFingerprintEnabled(false);
          Utils.showToast('Đã tắt đăng nhập bằng vân tay');
        });
        return;
      }

      // Bật vân tay — kiểm tra thiết bị trước
      if (!await BiometricService.isSupported()) {
        Utils.showToast('Thiết bị không hỗ trợ vân tay / Face ID');
        return;
      }
      if (!await BiometricService.canCheck()) {
        Utils.showToast('Vui lòng cài đặt vân tay trong Cài đặt máy');
        return;
      }
      if (!await BiometricService.authenticate()) {
        Utils.showToast('Xác nhận vân tay thất bại');
        return;
      }

      isFingerprintEnabled.value = true;
      AppGetStorage.setFingerprintEnabled(true);
      Utils.showToast('Đã bật đăng nhập bằng vân tay');
    } finally {
      isBusy.value = false;
    }
  }

  // ─── 4. ĐỔI MÃ PIN ──────────────────────────────────────────────────────────

  Future<void> changePin() async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      // Chưa có PIN → tạo mới ngay
      if (!AppGetStorage.hasPin()) {
        await Get.toNamed(PinVerifyPage.routeName);
        return;
      }

      // Đã có PIN → xác thực trước khi đổi
      await _verifyThenRun(() async {
        DialogUtils.showProgressDialog();
        await Future.delayed(const Duration(milliseconds: 300));
        if (Get.isDialogOpen ?? false) Get.back();

        await Get.toNamed(PinVerifyPage.routeName, arguments: FromType.changePassword);
      });
    } finally {
      isBusy.value = false;
    }
  }
}
