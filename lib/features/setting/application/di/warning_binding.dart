import 'package:get/get.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/features/setting/application/controller/warning_controller.dart';

class WarningBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.lazyPut(() => WarningController());
  }
}
