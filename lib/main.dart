import 'package:flutter/material.dart';
import 'package:keep_link/app/app.dart';
import 'package:keep_link/app/app_config.dart';
import 'package:keep_link/app/quick_share_app.dart';

void main() async {
  await appConfig();
  runApp(const App());
}

@pragma('vm:entry-point')
Future<void> quickShareMain() async {
  await quickShareConfig();
  runApp(const QuickShareApp());
}
