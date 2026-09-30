import 'package:get/get.dart';
import 'package:keep_link/core/services/backend/friend_connection_service.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';

class FriendProfileConfirmController extends GetxController {
  FriendProfileConfirmController({
    required this.payload,
    required this.friendController,
  });

  final FriendConnectionPayload payload;
  final FriendController friendController;
  final RxBool isSubmitting = false.obs;

  Future<void> sendFriendRequest() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;

    try {
      final success = await friendController.addFriendFromLink(payload.rawLink);
      if (!isClosed && success) {
        Get.back(result: true);
      }
    } finally {
      if (!isClosed) {
        isSubmitting.value = false;
      }
    }
  }

  void cancel() => Get.back(result: false);
}
