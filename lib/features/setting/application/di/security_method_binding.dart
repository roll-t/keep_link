import 'package:get/get.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/features/setting/application/controller/security_method_controller.dart';

class SecurityMethodBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.lazyPut(() => SecurityMethodController());
  }
}
