import 'dart:io';

import 'package:flutter/material.dart';

class Utils {
  static void dimissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  static void ignoreException() {
    FlutterError.onError = (FlutterErrorDetails details) {
      final exception = details.exception;
      if (exception is HttpException && exception.message.contains('403')) {
        return;
      }
      FlutterError.presentError(details);
    };
  }
}
