import 'package:keep_link/core/local_storage/sql_lite.dart';
import 'package:keep_link/features/category/data/model/category_model.dart';

Future<void> appConfig() async {
  DbHelper.registerModel(CategoryModel(id: '', name: ''));
}
