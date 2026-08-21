import 'package:get/get.dart';
import 'package:keep_link/core/di/dependency_utils.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/header_link_collection_controller.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/link_collection_controller.dart';

class LinkCollectionBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.lazyPut(() => LinkCollectionController());
    DependencyUtils.lazyPut(() => HeaderLinkCollectionController());
    // permanent: true — these hold the Firebase realtime watchers (friend
    // requests, friends count, shared-category access) that keep the header
    // badge and FriendPage's "Shared" tab live. Registering them here, once,
    // at the home screen means they stay connected for the whole session
    // instead of every FriendPage visit re-fetching from Firebase.
    DependencyUtils.put(() => FriendController(), permanent: true);
    DependencyUtils.put(() => SharedCategoryController(), permanent: true);
  }
}
