import 'package:get/get.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/downloaded_video_controller.dart';

class DownloadedVideoBinding extends Bindings {
  @override
  void dependencies() {
    final raw = Get.arguments;
    final args = raw is DownloadedVideoArguments
        ? raw
        : raw is Map
        ? DownloadedVideoArguments(
            filePath: raw['filePath'] as String? ?? '',
            title: raw['title'] as String? ?? '',
          )
        : throw StateError('DownloadedVideoBinding requires DownloadedVideoArguments.');

    Get.lazyPut(() => DownloadedVideoController(filePath: args.filePath, title: args.title));
  }
}
