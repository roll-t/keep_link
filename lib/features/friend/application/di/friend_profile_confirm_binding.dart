import 'package:get/get.dart';
import 'package:keep_link/core/services/backend/friend_connection_service.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_profile_confirm_controller.dart';

class FriendProfileConfirmBinding extends Bindings {
  FriendProfileConfirmBinding({
    required this.payload,
    required this.friendController,
  });

  final FriendConnectionPayload payload;
  final FriendController friendController;

  @override
  void dependencies() {
    Get.lazyPut<FriendProfileConfirmController>(
      () => FriendProfileConfirmController(
        payload: payload,
        friendController: friendController,
      ),
    );
  }
}
