import 'package:get/get.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/core/utils/controller/deep_link_controller.dart';
import 'package:keep_link/features/link/application/controller/add_link_controller.dart';

class AddLinkBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.lazyPut(() => AddLinkController());
    DependencyUtils.lazyPut(() => DeepLinkController());
  }
}
