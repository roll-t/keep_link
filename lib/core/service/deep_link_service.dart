import 'dart:async';

import 'package:receive_intent/receive_intent.dart';

class DeepLinkService {
  static String? sharedText;
  static bool _initialized = false;
  static bool isOpenedFromShare = false;

  static Function(String value, {required bool fromColdStart})? onReceive;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final initialIntent = await ReceiveIntent.getInitialIntent();
    if (initialIntent != null) {
      _processIntent(initialIntent, fromColdStart: true);
    }

    ReceiveIntent.receivedIntentStream.listen((intent) {
      if (intent != null) {
        _processIntent(intent, fromColdStart: false);
      }
    });
  }

  static void _processIntent(Intent intent, {required bool fromColdStart}) {
    final text = intent.extra?["android.intent.extra.TEXT"];
    if (text == null) return;
    isOpenedFromShare = true;
    sharedText = text;

    if (onReceive != null) {
      onReceive!(text, fromColdStart: fromColdStart);
    }
  }
}
