import 'package:get/get.dart';
import 'package:keep_link/core/service/internet_service.dart';

class InternetController extends GetxController {
  final _service = Get.find<InternetService>();

  @override
  void onReady() async {
    super.onReady();
    if (!Get.isDialogOpen!) {
      final check = await _service.checkNetwork();
      _service.showSnackbar(check);
    }
  }
}
