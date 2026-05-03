import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Wrapper around Google Play In-App Update API.
/// Only active on Android — all calls are no-ops on iOS.
class InAppUpdateService {
  InAppUpdateService._();

  /// Kiểm tra và hiển thị flexible update nếu có bản mới.
  /// Gọi khi app khởi động (splash) hoặc khi app resume từ background.
  static Future<void> checkForUpdate() async {
    if (!Platform.isAndroid || kDebugMode) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        // Sau khi tải xong, áp dụng bản cập nhật ngay khi user quay lại app
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      // Update check không được throw crash app — chỉ log
      log('InAppUpdateService: $e');
    }
  }
}
