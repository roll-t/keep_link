import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';
import 'package:keep_link/core/local_storage/sql_lite.dart';
import 'package:keep_link/core/service/biometric_service.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/application/controller/custom_popup_controller.dart';
import 'package:keep_link/features/category/data/model/category_model.dart';
import 'package:keep_link/features/security/presentation/page/pin_verify_page.dart';
import 'package:keep_link/features/security/presentation/widget/pin_verify_form.dart';

class SecurityMethodController extends GetxController {
  final isAppSecurityEnabled = false.obs;
  final isFingerprintEnabled = false.obs;
  final isCategorySecurityEnabled = false.obs;

  // Trạng thái đã xác thực thành công khi vào màn hình Cài đặt Bảo mật
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

  /// =========================================================
  /// KIỂM TRA BẢO MẬT KHI VỪA VÀO MÀN HÌNH SETTINGS
  /// =========================================================
  Future<void> _initialSecurityCheck() async {
    if (!isAppSecurityEnabled.value && !isCategorySecurityEnabled.value) {
      isVerified.value = true;
      return;
    }

    await Future.delayed(const Duration(milliseconds: 200));

    if (isFingerprintEnabled.value && await BiometricService.canCheck()) {
      final authSuccess = await BiometricService.authenticate();
      if (authSuccess) {
        isVerified.value = true;
        return;
      }
    }

    DialogUtils.showPinDialog(
      onCompleted: () {
        if (Get.isDialogOpen ?? false) Get.back();
        isVerified.value = true;
      },
      onDismiss: () {
        if (!isVerified.value) Get.back();
      },
    );
  }

  /// =========================================================
  /// HÀM PHỤ TRỢ: YÊU CẦU XÁC THỰC KHI TẮT BẢO MẬT/ĐỔI MẬT KHẨU
  /// =========================================================
  void _verifyToProceed(Function onSuccess) async {
    if (isFingerprintEnabled.value && await BiometricService.canCheck()) {
      final authSuccess = await BiometricService.authenticate();
      if (authSuccess) {
        onSuccess();
        return;
      }
    }

    DialogUtils.showPinDialog(
      onCompleted: () {
        if (Get.isDialogOpen ?? false) Get.back();
        onSuccess();
      },
    );
  }

  Future<bool> _ensurePinExists() async {
    final savedPin = AppGetStorage.getPin();
    if (savedPin == null || savedPin.isEmpty) {
      final newPin = await Get.toNamed(PinVerifyPage.routeName);
      return newPin != null;
    }
    return true;
  }

  /// =========================================================
  /// 👉 HÀM MỚI: CẬP NHẬT TRẠNG THÁI CHO TẤT CẢ DANH MỤC TRONG DB
  /// =========================================================
  Future<void> _updateAllCategoriesVisibility(bool isSecure) async {
    try {
      final targetVisibility = isSecure ? VisibilityStatus.private : VisibilityStatus.public;
      final categoryRows = await DbHelper.getAll('categories');

      for (var row in categoryRows) {
        final cat = CategoryModel.fromJson(Map<String, dynamic>.from(row));

        if (cat.visibility != targetVisibility) {
          cat.visibility = targetVisibility;
          cat.updatedAt = DateTime.now();
          // Sửa thành dòng này:
          await DbHelper.update('categories', cat.id!, cat.toJson());
        }
      }
      log("🔄 Đã đồng bộ trạng thái ${targetVisibility.name} cho tất cả danh mục.");
    } catch (e) {
      log("❌ Lỗi khi đồng bộ trạng thái danh mục: $e");
    }
  }

  /// =========================================================
  /// 1. BẬT / TẮT BẢO MẬT ỨNG DỤNG
  /// =========================================================
  void toggleAppSecurity() async {
    if (!isAppSecurityEnabled.value) {
      final success = await _ensurePinExists();
      if (success) {
        isAppSecurityEnabled.value = true;
        AppGetStorage.setSecurityEnabled(true);
        Utils.showToast("Đã bật bảo mật ứng dụng");
      }
    } else {
      _verifyToProceed(() {
        isAppSecurityEnabled.value = false;
        AppGetStorage.setSecurityEnabled(false);

        if (isFingerprintEnabled.value) {
          isFingerprintEnabled.value = false;
          AppGetStorage.setFingerprintEnabled(false);
        }
        Utils.showToast("Đã tắt bảo mật ứng dụng");
      });
    }
  }

  /// =========================================================
  /// 2. BẬT / TẮT BẢO MẬT DANH MỤC
  /// =========================================================
  void toggleCategorySecurity() async {
    if (!isCategorySecurityEnabled.value) {
      // Đang Tắt -> Muốn Bật
      final success = await _ensurePinExists();
      if (success) {
        isCategorySecurityEnabled.value = true;
        AppGetStorage.setCategorySecurity(true);

        // 👉 GỌI HÀM ĐỒNG BỘ: Chuyển tất cả category thành Private
        await _updateAllCategoriesVisibility(true);

        Utils.showToast("Đã bật bảo mật danh mục");
        _updateCustomPopupStatus();
      }
    } else {
      // Đang Bật -> Muốn Tắt
      _verifyToProceed(() async {
        isCategorySecurityEnabled.value = false;
        AppGetStorage.setCategorySecurity(false);

        // 👉 GỌI HÀM ĐỒNG BỘ: Chuyển tất cả category thành Public
        await _updateAllCategoriesVisibility(false);

        Utils.showToast("Đã tắt bảo mật danh mục");
        _updateCustomPopupStatus();
      });
    }
  }

  void _updateCustomPopupStatus() {
    if (Get.isRegistered<CustomPopupController>()) {
      DependencyUtils.put(() => CustomPopupController()).isEnableSecurity =
          isCategorySecurityEnabled.value;
    }
  }

  /// =========================================================
  /// 3. BẬT / TẮT VÂN TAY
  /// =========================================================
  void toggleFingerprint() async {
    final savedPin = AppGetStorage.getPin();
    if (savedPin == null) {
      Utils.showToast("Vui lòng thiết lập mã PIN trước");
      return;
    }

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
      Utils.showToast("Xác nhận vân tay thất bại");
      return;
    }

    isFingerprintEnabled.value = true;
    AppGetStorage.setFingerprintEnabled(true);
    Utils.showToast("Đã bật đăng nhập bằng vân tay");
  }

  /// =========================================================
  /// 4. ĐỔI MÃ PIN
  /// =========================================================
  void changePin() async {
    final savedPin = AppGetStorage.getPin();
    if (savedPin == null) {
      await Get.toNamed(PinVerifyPage.routeName);
      return;
    }

    _verifyToProceed(() async {
      DialogUtils.showProgressDialog();
      await Future.delayed(const Duration(milliseconds: 300));
      if (Get.isDialogOpen ?? false) Get.back();

      await Get.toNamed(PinVerifyPage.routeName, arguments: FromType.changePassword);
    });
  }
}
