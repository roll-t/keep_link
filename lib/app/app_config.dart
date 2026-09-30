import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:keep_link/app/app_lifecycle_observer.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/data/cache/sql_lite.dart';
import 'package:keep_link/core/localization/translation_service.dart';
import 'package:keep_link/core/services/platform/deep_link_service.dart';
import 'package:keep_link/core/services/platform/fcm_push_service.dart';
import 'package:keep_link/core/services/platform/local_notification_service.dart';
import 'package:keep_link/core/services/backend/session_sync_service.dart';
import 'package:keep_link/core/services/backend/single_device_session_service.dart';
import 'package:keep_link/core/config/theme/theme_service.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

import 'firebase_options.dart';

Future<void> appConfig() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  DbHelper.registerModel(CategoryModel(id: ''));
  DbHelper.registerModel(LinkModel(id: ''));
  DbHelper.registerModel(FriendModel(id: ''));

  await DeepLinkService.init();
  await GetStorage.init();

  // Xoá dữ liệu cũ nếu đây là lần đầu chạy sau khi cài đặt (hoặc cài lại).
  if (AppGetStorage.isFirstLaunch()) {
    await DbHelper.resetDatabase();
    AppCache.invalidateAll();
    AppGetStorage.clearUserData();
    AppGetStorage.markLaunched();
  }

  // Local notification channel setup does not gate the first frame.
  unawaited(LocalNotificationService.init());
  unawaited(FcmPushService.initialize());

  await LocalizationService.initialize();

  // Initialize theme service to load saved theme preference
  await ThemeService.initialize();

  Utils.ignoreException();
  WidgetsBinding.instance.addObserver(AppLifecycleHandler());

  // Session validation and cloud reconciliation may each wait up to the
  // network timeout. Preserve their order, but do not keep the first Flutter
  // frame waiting for them; the session service can safely sign out/navigate
  // after the app has mounted if another device owns the account.
  unawaited(_startAccountBackgroundWork());

  // Debug only — uncomment to wipe DB + cache:
  // await DbHelper.resetDatabase();
  // AppCache.invalidateAll();
}

Future<void> _startAccountBackgroundWork() async {
  await SingleDeviceSessionService.instance.initialize();

  // Push changes queued in the previous session, then reconcile local data.
  // Reconcile is throttled to once per 24 hours.
  await SessionSyncService.instance.flushPersistedQueue();
  await SessionSyncService.instance.reconcileLocalToFirebase();
}

/// Lightweight bootstrap used only by Android's translucent share activity.
/// It intentionally skips notifications, update checks and account reconcile
/// so the quick-save card can appear without launching the full application.
Future<void> quickShareConfig() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  DbHelper.registerModel(CategoryModel(id: ''));
  DbHelper.registerModel(LinkModel(id: ''));
  DbHelper.registerModel(FriendModel(id: ''));

  await GetStorage.init();
  if (AppGetStorage.isFirstLaunch()) {
    await DbHelper.resetDatabase();
    AppCache.invalidateAll();
    AppGetStorage.clearUserData();
    AppGetStorage.markLaunched();
  }

  await DeepLinkService.init();
  await LocalizationService.initialize();
  await ThemeService.initialize();
}
