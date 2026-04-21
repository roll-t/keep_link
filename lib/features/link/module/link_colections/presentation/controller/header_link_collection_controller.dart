import 'package:get/get.dart';
import 'package:keep_link/features/friend/presentation/page/friend_page.dart';

class HeaderLinkCollectionController extends GetxController {
  void openFriends() {
    Get.toNamed(FriendPage.routeName);
  }
}
