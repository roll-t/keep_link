import 'dart:io';

import 'package:flutter/services.dart';

class OverlayPermission {
  static const platform = MethodChannel('keep_link/overlay_permission');

  static Future<bool> check() async {
    if (!Platform.isAndroid) return false;
    return await platform.invokeMethod('checkPermission');
  }

  static Future<void> request() async {
    if (!Platform.isAndroid) return;
    await platform.invokeMethod('requestPermission');
  }
}
