import 'package:get/get.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/link_detail_controller.dart';

class LinkDetailBinding extends Bindings {
  @override
  void dependencies() {
    final raw = Get.arguments;
    final args = raw is LinkDetailArguments
        ? raw
        : LinkDetailArguments(link: raw as LinkModel);
    Get.lazyPut(
      () => LinkDetailController(link: args.link, readOnly: args.readOnly),
    );
  }
}
