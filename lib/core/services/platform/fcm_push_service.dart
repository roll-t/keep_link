import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/constants/push_notification_config.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/services/platform/local_notification_service.dart';
import 'package:keep_link/features/friend/application/di/friend_binding.dart';
import 'package:keep_link/features/friend/application/di/share_conversation_binding.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/page/friend_page.dart';
import 'package:keep_link/features/friend/presentation/page/share_conversation_page.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Khi app đang đóng hoặc chạy ngầm, Google FCM tự động hiển thị thông báo
  // nếu message có chứa `notification` payload.
  if (kDebugMode) {
    debugPrint('[FCM] Background message received: ${message.messageId}');
  }
}

class FcmPushService {
  FcmPushService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  static bool _initialized = false;
  static String? _currentToken;

  /// Khởi tạo Firebase Messaging, xin quyền và cấu hình listeners
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Xin quyền thông báo (hỗ trợ Android 13+ & iOS)
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
      }

      // Lấy FCM token của thiết bị này
      _currentToken = await _fcm.getToken();
      if (kDebugMode) {
        debugPrint('[FCM] Device Token: $_currentToken');
      }

      // Cập nhật token lên Firebase Database nếu đã đăng nhập
      await syncTokenToFirebase(_currentToken);

      // Lắng nghe khi token được Google làm mới
      _fcm.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        syncTokenToFirebase(newToken);
      });

      // Kết nối callback mở trang trò chuyện khi bấm thông báo cục bộ
      LocalNotificationService.onNotificationTap = handlePayloadNavigation;

      // Lắng nghe thông báo khi app ĐANG MỞ (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('[FCM] Foreground message: ${message.notification?.title}');
        }
        final title = message.notification?.title ??
            (message.data['friendName'] ?? message.data['senderName'] ?? 'Linkeep').toString();
        final body = message.notification?.body ?? 'Đã gửi cho bạn một link mới';

        // Hiển thị thông báo cục bộ với âm thanh và kèm payload điều hướng
        LocalNotificationService.showSharedCategoryNotification(
          title: title,
          body: body,
          payload: jsonEncode(message.data),
        );

        // Kích hoạt chấm đỏ ngoài Home
        FriendController.hasUnreadShare.value = true;
      });

      // Lắng nghe khi người dùng BẤM vào thông báo để mở app từ Background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        handlePayloadNavigation(message.data);
      });

      // Kiểm tra nếu app được mở từ trạng thái TẮT HOÀN TOÀN bằng việc bấm thông báo
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handlePayloadNavigation(initialMessage.data);
        });
      }

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Initialize error: $e');
      }
    }
  }

  /// Điều hướng khi người dùng chạm vào thông báo (cả FCM lẫn Local Notification)
  static void handlePayloadNavigation(Map<String, dynamic> data) {
    if (kDebugMode) {
      debugPrint('[FCM] User tapped notification with data: $data');
    }

    final type = data['type']?.toString();
    final friendUid = (data['friendUid'] ?? data['fromUserId'])?.toString();

    // 1. Nếu là lời mời kết bạn hoặc không có friendUid: mở trang Trao đổi link / Quản lý bạn bè
    if (type == 'friend_request' || friendUid == null || friendUid.isEmpty) {
      Get.toNamed(FriendPage.routeName);
      return;
    }

    // 2. Nếu là chia sẻ link hoặc danh mục: Mở thẳng cuộc trò chuyện trao đổi với bạn bè đó
    try {
      if (!Get.isRegistered<FriendController>()) {
        FriendBinding().dependencies();
      }

      final friendName =
          (data['friendName'] ?? data['senderName'] ?? '').toString();
      final friendPhotoUrl = data['friendPhotoUrl']?.toString();

      final friend = AppCache.friends.firstWhereOrNull(
            (f) => f.friendUserId == friendUid,
          ) ??
          FriendModel(
            friendUserId: friendUid,
            displayName: friendName.isNotEmpty ? friendName : 'Bạn bè',
            photoUrl: friendPhotoUrl,
          );

      // Đưa FriendPage vào ngăn xếp để khi người dùng nhấn Back thì quay về màn hình Trao đổi link
      Get.toNamed(FriendPage.routeName);
      Get.toNamed(
        ShareConversationPage.routeName,
        arguments: ShareConversationArguments(friend: friend),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Error navigating to conversation: $e');
      }
      Get.toNamed(FriendPage.routeName);
    }
  }

  /// Đồng bộ FCM Token của thiết bị lên Firebase Realtime Database
  static Future<void> syncTokenToFirebase([String? token]) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final fcmToken = token ?? _currentToken;
    if (uid == null || fcmToken == null || fcmToken.isEmpty) return;

    try {
      await FirebaseDatabase.instance.ref('users/$uid/fcmToken').set(fcmToken);
      if (kDebugMode) {
        debugPrint('[FCM] Synced token for user $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Failed to sync token: $e');
      }
    }
  }

  /// Xoá FCM Token khỏi Firebase khi người dùng đăng xuất
  static Future<void> clearTokenFromFirebase() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseDatabase.instance.ref('users/$uid/fcmToken').remove();
    } catch (_) {}
  }

  /// Gửi push notification đến thiết bị bạn bè thông qua Cloudflare Worker
  static Future<void> sendPushNotification({
    required String receiverUid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final sender = FirebaseAuth.instance.currentUser;
    if (sender == null || receiverUid.trim().isEmpty) return;

    // Bỏ qua nếu chưa cấu hình Cloudflare Worker URL
    if (PushNotificationConfig.workerUrl.contains('YOUR_WORKER_SUBDOMAIN')) {
      if (kDebugMode) {
        debugPrint(
          '[FCM] Cloudflare Worker URL chưa được cấu hình trong push_notification_config.dart',
        );
      }
      return;
    }

    try {
      final senderDisplayName = sender.displayName?.trim().isNotEmpty == true
          ? sender.displayName!
          : 'Bạn bè';
      final payload = {
        'secret': PushNotificationConfig.apiSecret,
        'senderUid': sender.uid,
        'senderName': senderDisplayName,
        'receiverUid': receiverUid.trim(),
        'title': title,
        'body': body,
        'data': {
          'type': 'share',
          'friendUid': sender.uid,
          'friendName': senderDisplayName,
          'friendPhotoUrl': sender.photoURL ?? '',
          ...?data,
        },
      };

      final response = await _dio.post(
        PushNotificationConfig.workerUrl,
        data: jsonEncode(payload),
      );

      if (kDebugMode) {
        debugPrint('[FCM] Sent notification via Cloudflare Worker: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Error sending push via Cloudflare Worker: $e');
      }
    }
  }
}
