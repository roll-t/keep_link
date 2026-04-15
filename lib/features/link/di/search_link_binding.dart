import 'package:get/get.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/features/link/application/controller/search_link_controller.dart';

class SearchLinkBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.lazyPut(() => SearchLinkController());
  }
}
