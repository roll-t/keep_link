import 'package:get/get.dart';
import 'package:keep_link/core/di/dependency_utils.dart';
import 'package:keep_link/features/link/module/link_search/presentation/controller/search_link_controller.dart';

class SearchLinkBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.lazyPut(() => SearchLinkController());
  }
}
