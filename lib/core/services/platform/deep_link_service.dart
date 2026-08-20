import 'dart:async';

import 'package:receive_intent/receive_intent.dart';

class DeepLinkService {
  static String? sharedText;
  static bool _initialized = false;
  static bool isOpenedFromShare = false;
  static StreamSubscription? _subscription;

  static Function(String value, {required bool fromColdStart})? onReceive;

  static Future<void> init() async {
    // Reset state on every app open so stale flags don't persist
    sharedText = null;
    isOpenedFromShare = false;

    try {
      final initialIntent = await ReceiveIntent.getInitialIntent();
      if (initialIntent != null) {
        _processIntent(initialIntent, fromColdStart: true);
      }
    } catch (_) {}

    // Only subscribe to the live-intent stream once
    if (_initialized) return;
    _initialized = true;

    _subscription = ReceiveIntent.receivedIntentStream.listen((intent) {
      if (intent != null) {
        _processIntent(intent, fromColdStart: false);
      }
    });
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;
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
