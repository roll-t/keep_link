import 'package:get/get.dart';
import 'package:keep_link/core/utils/binding/dependency_utils.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';

class FriendBinding extends Bindings {
  @override
  void dependencies() {
    DependencyUtils.lazyPut(() => FriendController(), fenix: true);
  }
}
