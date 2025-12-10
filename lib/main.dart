import 'package:flutter/material.dart';
import 'package:keep_link/app.dart';
import 'package:keep_link/app_config.dart';
import 'package:keep_link/core/service/native_bridge.dart';

void main() async {
  await appConfig();
  NativeBridge.init();
  runApp(const App());
}
