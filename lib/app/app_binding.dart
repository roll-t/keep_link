import 'package:get/get.dart';
import 'package:keep_link/core/state/controllers/theme_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() async {
    Get.lazyPut(() => ThemeController());
  }
}
