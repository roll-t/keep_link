import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _friendChannelId = 'keep_link_friends';
  static const _friendChannelName = 'Friends';

  static const _sharedChannelId = 'keep_link_shared';
  static const _sharedChannelName = 'Shared Categories';

  static bool _initialized = false;

  // ── Init ───────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(android: androidSettings, iOS: darwinSettings);

    await _plugin.initialize(settings);

    // Android 8+: tạo notification channels
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _friendChannelId,
          _friendChannelName,
          importance: Importance.high,
          enableVibration: true,
        ),
      );

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _sharedChannelId,
          _sharedChannelName,
          importance: Importance.high,
          enableVibration: true,
        ),
      );

      // Xin quyền POST_NOTIFICATIONS (Android 13+)
      await androidPlugin?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  // ── Show helpers ───────────────────────────────────────────────────────

  /// Thông báo lời mời kết bạn mới
  static Future<void> showFriendRequestNotification({
    required String title,
    required String body,
  }) async {
    if (kDebugMode) debugPrint('[LocalNotif] friend_request: $body');
    await _show(
      id: 1001,
      title: title,
      body: body,
      channelId: _friendChannelId,
      channelName: _friendChannelName,
    );
  }

  /// Thông báo nhận danh mục chia sẻ mới
  static Future<void> showSharedCategoryNotification({
    required String title,
    required String body,
  }) async {
    if (kDebugMode) debugPrint('[LocalNotif] shared_category: $body');
    await _show(
      id: 1002,
      title: title,
      body: body,
      channelId: _sharedChannelId,
      channelName: _sharedChannelName,
    );
  }

  // ── Internal ───────────────────────────────────────────────────────────

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    if (!_initialized) await init();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    await _plugin.show(id, title, body, details);
  }
}
