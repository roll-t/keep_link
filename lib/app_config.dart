import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:keep_link/app_lifecycle_observer.dart';
import 'package:keep_link/core/local_storage/sql_lite.dart';
import 'package:keep_link/core/service/deep_link_service.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/data/model/category_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

Future<void> appConfig() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DeepLinkService.init();
  await GetStorage.init();
  Utils.ignoreException();
  WidgetsBinding.instance.addObserver(AppLifecycleHandler());

  // Đăng ký model
  DbHelper.registerModel(CategoryModel(id: ''));
  DbHelper.registerModel(LinkModel(id: ''));
  // Reset database -> Xóa sạch & tạo lại table
  // await DbHelper.resetDatabase();
}
