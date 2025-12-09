import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keep_link/core/config/app_colors.dart';

class OverlayHandler {
  static const MethodChannel _channel = MethodChannel("overlay_channel");
  static final navigatorKey = GlobalKey<NavigatorState>();

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "showOverlay") {
        final args = call.arguments as Map;
        final route = args["route"];
        final url = args["url"];

        showDialog(
          context: navigatorKey.currentContext!,
          barrierColor: AppColors.transparent,
          builder: (_) => Center(
            child: Container(
              padding: EdgeInsets.all(20),
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Route: $route"),
                  SizedBox(height: 10),
                  Text("URL: $url"),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(navigatorKey.currentContext!).pop();
                    },
                    child: Text("Close"),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });
  }
}
