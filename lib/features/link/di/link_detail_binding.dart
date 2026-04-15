import 'package:get/get.dart';
import 'package:keep_link/features/link/application/controller/link_detail_controller.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

class LinkDetailBinding extends Bindings {
  @override
  void dependencies() {
    final link = Get.arguments as LinkModel;
    Get.lazyPut(() => LinkDetailController(link: link));
  }
}
