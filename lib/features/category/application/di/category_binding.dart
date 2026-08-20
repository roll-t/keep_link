import 'package:get/get.dart';
import 'package:keep_link/core/di/dependency_utils.dart';
import 'package:keep_link/features/category/presentation/controller/category_controller.dart';

class CategoryBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.put(() => CategoryController());
  }
}
