import 'package:get/get.dart';
import 'package:keep_link/features/link/presentation/page/link_collection_page.dart';

class SplashController extends GetxController {
  @override
  void onInit() async {
    await Future.delayed(Duration(milliseconds: 50));
    Get.offAndToNamed(LinkCollectionPage.routeName);
    super.onInit();
  }
}
