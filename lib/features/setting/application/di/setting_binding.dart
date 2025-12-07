import 'package:get/get.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/features/setting/application/controller/setting_controller.dart';

class SettingBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.lazyPut(() => SettingController());
  }
}
