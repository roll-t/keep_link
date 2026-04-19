import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/core/service/in_app_update_service.dart';

class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      InAppUpdateService.checkForUpdate();
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
