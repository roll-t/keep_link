import 'package:get/get.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/presentation/controller/share_conversation_controller.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';

class ShareConversationArguments {
  const ShareConversationArguments({required this.friend});

  final FriendModel friend;
}

class ShareConversationBinding extends Bindings {
  @override
  void dependencies() {
    final raw = Get.arguments;
    final args = raw is ShareConversationArguments
        ? raw
        : raw is FriendModel
        ? ShareConversationArguments(friend: raw)
        : throw StateError(
            'ShareConversationPage requires a FriendModel argument.',
          );

    if (!Get.isRegistered<SharedCategoryController>()) {
      Get.lazyPut<SharedCategoryController>(
        SharedCategoryController.new,
        fenix: true,
      );
    }

    Get.lazyPut<ShareConversationController>(
      () => ShareConversationController(friend: args.friend),
    );
  }
}
