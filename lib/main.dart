import 'package:flutter/material.dart';
import 'package:keep_link/app.dart';
import 'package:keep_link/app_config.dart';
import 'package:keep_link/overlay_handler.dart';

void main() async {
  await appConfig();
  OverlayHandler.init();
  runApp(const App());
}
