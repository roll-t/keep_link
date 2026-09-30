import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/downloaded_video_controller.dart';

class DownloadedVideoPage extends GetView<DownloadedVideoController> {
  static const routeName = '/DownloadedVideoPage';

  const DownloadedVideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: GestureDetector(onTap: () => Get.back(), child: Icon(Icons.arrow_back_ios)),
        title: TextWidget(
          text: controller.displayTitle,
          maxLines: 1,
          textStyle: AppTextStyle.regular18,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InAppWebView(
              initialData: InAppWebViewInitialData(
                data: controller.playerHtml,
                baseUrl: WebUri('file:///'),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                allowFileAccess: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: false,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                useHybridComposition: true,
                transparentBackground: false,
              ),
              onWebViewCreated: controller.onWebViewCreated,
            ),
            Obx(() {
              if (!controller.hasError.value) return const SizedBox.shrink();
              return ColoredBox(
                color: AppColors.black,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          'unable_to_open_video'.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
