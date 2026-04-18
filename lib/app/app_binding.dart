import 'package:get/get.dart';
import 'package:keep_link/core/utils/controller/theme_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() async {
    Get.lazyPut(() => ThemeController());
  }
}
