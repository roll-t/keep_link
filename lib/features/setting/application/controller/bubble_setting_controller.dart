import 'package:get/get.dart';
import 'package:keep_link/core/cache/app_get_storage.dart';
import 'package:keep_link/core/service/bubble_service.dart';
import 'package:keep_link/core/service/overlay_permission.dart';

class BubbleSettingController extends GetxController {
  // trạng thái observable để UI tự động cập nhật
  var isBubbleEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    // load trạng thái lưu trước đó
    isBubbleEnabled.value = AppGetStorage.read<bool>('bubble_enabled') ?? false;
  }

  Future<void> toggleBubble(bool value) async {
    final granted = await OverlayPermission.check();
    if (!granted) {
      await OverlayPermission.request();
      return;
    }

    isBubbleEnabled.value = value;
    AppGetStorage.write('bubble_enabled', value);

    if (value) {
      await BubbleService.startBubble();
    } else {
      await BubbleService.stopBubble();
    }
  }
}
