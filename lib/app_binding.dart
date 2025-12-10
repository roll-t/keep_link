import 'package:get/get.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/core/utils/controller/deep_link_controller.dart';
import 'package:keep_link/core/utils/controller/theme_controller.dart';
import 'package:keep_link/features/category/application/controller/custom_popup_controller.dart';
import 'package:keep_link/features/link/application/controller/add_link_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() async {
    Get.lazyPut(() => ThemeController());
    DependencyUtils.lazyPut(() => DeepLinkController());
    DependencyUtils.lazyPut(() => CustomPopupController());
    DependencyUtils.lazyPut(() => AddLinkController());
  }
}
