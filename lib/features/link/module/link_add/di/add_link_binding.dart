import 'package:get/get.dart';
import 'package:keep_link/core/di/dependency_utils.dart';
import 'package:keep_link/core/state/controllers/deep_link_controller.dart';
import 'package:keep_link/features/link/module/link_add/presentation/controller/add_link_controller.dart';

class AddLinkBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.lazyPut(() => AddLinkController());
    DependencyUtils.lazyPut(() => DeepLinkController());
  }
}
