import 'dart:async';

import 'package:get/get.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';
import 'package:keep_link/core/service/biometric_service.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/application/controller/custom_popup_controller.dart';
import 'package:keep_link/features/security/presentation/page/pin_verify_page.dart';
import 'package:keep_link/features/security/presentation/widget/pin_verify_form.dart';

class SecurityMethodController extends GetxController {
  final isAppSecurityEnabled = false.obs;
  final isFingerprintEnabled = false.obs;
  final isCategorySecurityEnabled = false.obs;
  final isVerified = false.obs;

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

  /// Kiểm tra bảo mật khi vừa vào màn hình
  Future<void> _initialSecurityCheck() async {
    // Nếu cả 2 đều tắt thì không cần check, cho thao tác luôn
    if (!isAppSecurityEnabled.value && !isCategorySecurityEnabled.value) {
      isVerified.value = true;
      return;
    }

    // Nếu 1 trong 2 đang bật -> Yêu cầu xác thực
    DialogUtils.showPinDialog(
      onCompleted: () {
        if (Get.isDialogOpen ?? false) Get.back(); // Đóng dialog PIN
        isVerified.value = true; // Cho phép thao tác
      },
      onDismiss: () {
        // Nếu người dùng hủy/không nhập đúng -> Đuổi về trang trước
        if (!isVerified.value) {
          Get.back();
        }
      },
    );
  }

  /// =========================================================
  /// 1. TOGGLE APP SECURITY (BẢO MẬT ỨNG DỤNG)
  /// =========================================================
  void toggleAppSecurity() async {
    // Logic: Muốn bật thì phải đảm bảo đã có PIN. Không phụ thuộc vào Category.
    if (!isAppSecurityEnabled.value) {
      // Đang Tắt -> Muốn Bật
      final success = await _ensurePinExists();
      if (success) {
        isAppSecurityEnabled.value = true;
        AppGetStorage.setSecurityEnabled(true);
        Utils.showToast("Đã bật bảo mật ứng dụng");
      }
    } else {
      // Đang Bật -> Muốn Tắt
      isAppSecurityEnabled.value = false;
      AppGetStorage.setSecurityEnabled(false);

      // Tắt luôn vân tay nếu App Security tắt (Tuỳ logic, thường là nên tắt theo)
      if (isFingerprintEnabled.value) {
        isFingerprintEnabled.value = false;
        AppGetStorage.setFingerprintEnabled(false);
      }
      Utils.showToast("Đã tắt bảo mật ứng dụng");
    }
  }

  /// =========================================================
  /// 2. TOGGLE CATEGORY SECURITY (BẢO MẬT DANH MỤC)
  /// =========================================================
  void toggleCategorySecurity() async {
    // YÊU CẦU 2: Độc lập hoàn toàn với App Security
    if (!isCategorySecurityEnabled.value) {
      // Đang Tắt -> Muốn Bật
      // Chỉ cần kiểm tra xem đã thiết lập PIN chưa
      final success = await _ensurePinExists();
      if (success) {
        isCategorySecurityEnabled.value = true;
        AppGetStorage.setCategorySecurity(true);
        Utils.showToast("Đã bật bảo mật danh mục");
      }
    } else {
      // Đang Bật -> Muốn Tắt
      isCategorySecurityEnabled.value = false;
      AppGetStorage.setCategorySecurity(false);
      Utils.showToast("Đã tắt bảo mật danh mục");
    }

    if (Get.isRegistered<CustomPopupController>()) {
      DependencyUtils.put(() => CustomPopupController()).isEnableSecurity =
          isCategorySecurityEnabled.value;
    }
  }

  /// Hàm phụ trợ: Đảm bảo người dùng đã có PIN trước khi bật tính năng bảo mật nào đó
  Future<bool> _ensurePinExists() async {
    final savedPin = AppGetStorage.getPin();
    if (savedPin == null || savedPin.isEmpty) {
      // Chưa có PIN -> Dẫn sang trang tạo PIN
      final newPin = await Get.toNamed(PinVerifyPage.routeName);
      return newPin != null; // Trả về true nếu tạo thành công
    }
    return true; // Đã có PIN
  }

  /// =========================================================
  /// 3. TOGGLE FINGERPRINT (VÂN TAY)
  /// =========================================================
  void toggleFingerprint() async {
    // Vân tay chỉ hoạt động khi ĐÃ CÓ PIN (làm fallback)
    final savedPin = AppGetStorage.getPin();
    if (savedPin == null) {
      Utils.showToast("Vui lòng thiết lập mã PIN trước");
      return;
    }

    // Nếu muốn bắt buộc phải bật "Bảo mật App" mới cho dùng vân tay thì giữ lại check này.
    // Nếu muốn vân tay độc lập (chỉ cần có PIN) thì bỏ check bên dưới đi.
    // Tại đây tôi giữ logic: Phải bật Bảo mật App thì mới cho bật Vân tay App.
    if (!isAppSecurityEnabled.value) {
      Utils.showToast("Vui lòng bật bảo mật ứng dụng trước");
      isFingerprintEnabled.value = false;
      return;
    }

    if (isFingerprintEnabled.value) {
      isFingerprintEnabled.value = false;
      AppGetStorage.setFingerprintEnabled(false);
      Utils.showToast("Đã tắt đăng nhập bằng vân tay");
      return;
    }

    // Check phần cứng
    if (!await BiometricService.isSupported()) {
      Utils.showToast("Thiết bị không hỗ trợ vân tay/FaceID");
      return;
    }

    if (!await BiometricService.canCheck()) {
      Utils.showToast("Vui lòng cài đặt vân tay trong Cài đặt máy");
      return;
    }

    final ok = await BiometricService.authenticate();
    if (!ok) {
      Utils.showToast("Xác thực vân tay thất bại");
      return;
    }

    isFingerprintEnabled.value = true;
    AppGetStorage.setFingerprintEnabled(true);
    Utils.showToast("Đã bật đăng nhập bằng vân tay");
  }

  /// =========================================================
  /// 4. CÁC HÀM TIỆN ÍCH KHÁC (CHANGE PIN, VERIFY...)
  /// =========================================================

  void changePin() async {
    // Logic đổi PIN: Phải nhập PIN cũ trước
    final savedPin = AppGetStorage.getPin();
    if (savedPin == null) {
      await Get.toNamed(PinVerifyPage.routeName);
      return;
    }

    DialogUtils.showPinDialog(
      onCompleted: () async {
        if (Get.isDialogOpen ?? false) Get.back();

        // Hiệu ứng chờ nhỏ để UX mượt hơn
        DialogUtils.showProgressDialog();
        await Future.delayed(const Duration(milliseconds: 300));
        if (Get.isDialogOpen ?? false) Get.back();

        await Get.toNamed(PinVerifyPage.routeName, arguments: FromType.changePassword);
      },
    );
  }
}
