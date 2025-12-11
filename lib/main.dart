import 'package:flutter/material.dart';
import 'package:keep_link/app.dart';
import 'package:keep_link/app_config.dart';

void main() async {
  await appConfig();
  runApp(const App());
}
