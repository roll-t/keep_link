import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:keep_link/app/app_lifecycle_observer.dart';
import 'package:keep_link/core/cache/sql_lite.dart';
import 'package:keep_link/core/lang/translation_service.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/core/service/session_sync_service.dart';
import 'package:keep_link/core/service/theme_service.dart';
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

  await LocalizationService.initialize();

  // Initialize theme service to load saved theme preference
  await ThemeService.initialize();

  Utils.ignoreException();
  WidgetsBinding.instance.addObserver(AppLifecycleHandler());

  // Push any changes that were queued in the previous session.
  // Runs after Firebase is ready; silently skips if not authenticated.
  await SessionSyncService.instance.flushPersistedQueue();

  // Reconcile: compare local SQLite with Firebase and push any missing records.
  // Throttled to once per 24 hours (max 1 GET + 1 UPDATE request).
  await SessionSyncService.instance.reconcileLocalToFirebase();

  // Debug only — uncomment to wipe DB + cache:
  // await DbHelper.resetDatabase();
  // AppCache.invalidateAll();
}
