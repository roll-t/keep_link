import 'package:get/get.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';

class SharedCategoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SharedCategoryController>(() => SharedCategoryController());
  }
}
