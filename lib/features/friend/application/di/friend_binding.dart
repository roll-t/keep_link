import 'package:get/get.dart';
import 'package:keep_link/core/di/dependency_utils.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';

class FriendBinding extends Bindings {
  @override
  void dependencies() {
    // Normally already permanently registered by LinkCollectionBinding (the
    // home screen) by the time this runs — see there for why. This is just a
    // defensive fallback for FriendPage's own route in case that ever
    // changes; DependencyUtils.put() is a no-op if already registered.
    DependencyUtils.put(() => FriendController(), permanent: true);
    DependencyUtils.put(() => SharedCategoryController(), permanent: true);
  }
}
