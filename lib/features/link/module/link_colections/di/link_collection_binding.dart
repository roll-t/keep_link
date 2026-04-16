import 'package:get/get.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/link_collection_controller.dart';

class LinkCollectionBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.lazyPut(() => LinkCollectionController());
  }
}
