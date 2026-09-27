import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  // Android notification-channel sound is immutable after the channel is
  // created. Version the IDs so existing installs receive the custom sound
  // instead of retaining the old default-sound channel configuration.
  static const _friendChannelId = 'keep_link_friends_sfx_v1';
  static const _friendChannelName = 'Friends';

  static const _sharedChannelId = 'keep_link_shared_sfx_v1';
  static const _sharedChannelName = 'Shared Categories';
  static const _androidSoundName = 'sfx_notification';
  static const _iosSoundFile = 'sfx_notification.wav';

  static bool _initialized = false;

  // ── Init ───────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(settings);

    // Android 8+: tạo notification channels
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _friendChannelId,
          _friendChannelName,
          importance: Importance.high,
          enableVibration: true,
          sound: RawResourceAndroidNotificationSound(_androidSoundName),
        ),
      );

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _sharedChannelId,
          _sharedChannelName,
          importance: Importance.high,
          enableVibration: true,
          sound: RawResourceAndroidNotificationSound(_androidSoundName),
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
      sound: const RawResourceAndroidNotificationSound(_androidSoundName),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: _iosSoundFile,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(id, title, body, details);
  }
}
