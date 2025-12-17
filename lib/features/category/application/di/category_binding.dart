import 'package:get/get.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/features/category/application/controller/category_controller.dart';

class CategoryBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.put(() => CategoryController());
  }
}
