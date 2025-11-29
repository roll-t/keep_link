import 'package:get/get.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/core/utils/controller/internet_controller.dart';

class InternetBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.put<InternetController>(() => InternetController());
  }
}
