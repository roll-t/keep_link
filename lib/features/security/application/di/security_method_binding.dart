import 'package:get/get.dart';
import 'package:keep_link/core/di/dependency_utils.dart';
import 'package:keep_link/features/security/application/controller/security_method_controller.dart';

class SecurityMethodBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.lazyPut(() => SecurityMethodController());
  }
}
