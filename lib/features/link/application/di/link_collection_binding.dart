import 'package:get/get.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/features/link/application/controller/header_link_collection_controller.dart';

class LinkCollectionBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.lazyPut(() => HeaderLinkCollectionController());
  }
}
