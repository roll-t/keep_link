import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/core/service/in_app_update_service.dart';
import 'package:keep_link/core/service/session_sync_service.dart';

class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      InAppUpdateService.checkForUpdate();
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
      if (DeepLinkService.isOpenedFromShare) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _closeApp();
        });
      }
    }
  }

  void _closeApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }
}
