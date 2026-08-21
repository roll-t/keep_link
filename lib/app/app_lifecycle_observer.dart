import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/services/platform/deep_link_service.dart';
import 'package:keep_link/core/services/platform/in_app_update_service.dart';
import 'package:keep_link/core/services/backend/session_sync_service.dart';
import 'package:keep_link/features/security/presentation/page/app_lock_page.dart';
import 'package:keep_link/features/splash/presentation/page/splash_page.dart';

class AppLifecycleHandler extends WidgetsBindingObserver {
  // Chỉ được set true khi app thực sự bị đưa xuống nền hoàn toàn (paused/detached),
  // không phải khi chỉ "inactive" thoáng qua (ví dụ hộp thoại vân tay hệ thống hiện lên) —
  // tránh việc chính hộp thoại xác thực của app lại tự trigger khoá lại app.
  bool _wasBackgrounded = false;
  bool _isLockScreenShowing = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      InAppUpdateService.checkForUpdate();
      _maybeShowLockScreen();
    }

    // Persist in-memory queue to storage whenever app leaves foreground.
    // Actual Firebase push happens at next launch (more reliable than on-close push).
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      SessionSyncService.instance.persistQueue();
    }

    if (state == AppLifecycleState.paused) {
      _wasBackgrounded = true;

      if (DeepLinkService.isOpenedFromShare) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _closeApp();
        });
      }
    }
  }

  /// Bắt buộc xác thực lại (PIN/vân tay) khi app quay lại foreground sau khi đã
  /// bị đưa xuống nền, nếu "Bảo mật ứng dụng" đang bật. Trước đây app chỉ khoá
  /// lúc khởi động (SplashPage) nên mở lại từ background hoàn toàn không hỏi lại
  /// PIN — đây là lỗ hổng chính khiến tính năng khoá ứng dụng gần như vô nghĩa.
  void _maybeShowLockScreen() {
    if (!_wasBackgrounded) return;
    _wasBackgrounded = false;

    if (_isLockScreenShowing) return;
    if (!AppGetStorage.isSecurityEnabled()) return;
    // SplashPage đã tự xử lý xác thực ban đầu của riêng nó — tránh chồng thêm
    // 1 màn khoá nữa nếu app bị backgroud ngay trong lúc còn đang ở màn splash.
    if (Get.currentRoute == SplashPage.routeName) return;

    _isLockScreenShowing = true;
    final future = Get.to<void>(() => const AppLockPage());
    if (future == null) {
      _isLockScreenShowing = false;
      return;
    }
    future.whenComplete(() => _isLockScreenShowing = false);
  }

  void _closeApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }
}
