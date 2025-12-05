import 'package:get/get.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/features/setting/application/controller/pin_verify_controller.dart';

class PinVerifyBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.lazyPut(() => PinVerifyController());
  }
}
