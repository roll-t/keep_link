import 'package:get/get.dart';
import 'package:keep_link/core/di/dependency_utils.dart';
import 'package:keep_link/features/personal/presentation/controller/personal_controller.dart';

class PersonalBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.lazyPut(() => PersonalController());
  }
}
