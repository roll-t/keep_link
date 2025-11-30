import 'package:flutter/material.dart';

class Utils {
  static void dimissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
