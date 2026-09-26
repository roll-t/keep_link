import 'package:flutter/services.dart';

class FloatingBubbleStatus {
  const FloatingBubbleStatus({
    required this.overlayGranted,
    required this.accessibilityGranted,
    required this.running,
  });

  final bool overlayGranted;
  final bool accessibilityGranted;
  final bool running;

  factory FloatingBubbleStatus.fromMap(Map<Object?, Object?>? value) {
    return FloatingBubbleStatus(
      overlayGranted: value?['overlayGranted'] == true,
      accessibilityGranted: value?['accessibilityGranted'] == true,
      running: value?['running'] == true,
    );
  }
}

class FloatingLinkBubbleService {
  FloatingLinkBubbleService._();

  static const MethodChannel _bubbleChannel = MethodChannel('keep_link/bubble');
  static const MethodChannel _permissionChannel = MethodChannel(
    'keep_link/overlay_permission',
  );

  static Future<FloatingBubbleStatus> getStatus() async {
    final result = await _bubbleChannel.invokeMapMethod<Object?, Object?>(
      'getBubbleStatus',
    );
    return FloatingBubbleStatus.fromMap(result);
  }

  static Future<void> requestOverlayPermission() =>
      _permissionChannel.invokeMethod<void>('requestPermission');

  static Future<void> requestAccessibilityPermission() =>
      _bubbleChannel.invokeMethod<void>('requestAccessibilityPermission');

  static Future<bool> start() async =>
      await _bubbleChannel.invokeMethod<bool>('startBubble') ?? false;

  static Future<void> stop() => _bubbleChannel.invokeMethod<void>('stopBubble');
}
