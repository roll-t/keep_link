import 'package:flutter/services.dart';

class BubbleService {
  static const _channel = MethodChannel('keep_link/bubble');
  static Future<void> startBubble() async {
    try {
      await _channel.invokeMethod('startBubble');
    } catch (e) {
      print(e);
    }
  }

  static Future<void> stopBubble() async {
    try {
      await _channel.invokeMethod('stopBubble');
    } on PlatformException catch (e) {
      print("Failed to stop bubble: ${e.message}");
    }
  }
}
