import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:keep_link/app_lifecycle_observer.dart';
import 'package:keep_link/core/cache/sql_lite.dart';
import 'package:keep_link/core/lang/translation_service.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/core/service/theme_service.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

Future<void> appConfig() async {
  WidgetsFlutterBinding.ensureInitialized();

  DbHelper.registerModel(CategoryModel(id: ''));
  DbHelper.registerModel(LinkModel(id: ''));

  await DeepLinkService.init();
  await GetStorage.init();

  await LocalizationService.initialize();

  // Initialize theme service to load saved theme preference
  await ThemeService.initialize();

  Utils.ignoreException();
  WidgetsBinding.instance.addObserver(AppLifecycleHandler());

  // Debug only — uncomment to wipe DB + cache:
  // await DbHelper.resetDatabase();
  // AppCache.invalidateAll();
}
