import 'package:get/get.dart';
import 'package:keep_link/core/di/dependency_utils.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';

class FriendBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.lazyPut(() => FriendController(), fenix: true);
    // The friends page now shows a "shared with you" preview inline, so this
    // controller needs to be ready as soon as the page opens instead of only
    // when navigating to SharedCategoriesPage.
    DependencyUtils.lazyPut(() => SharedCategoryController(), fenix: true);
  }
}
