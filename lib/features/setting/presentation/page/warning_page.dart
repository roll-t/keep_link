import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/setting/application/controller/warning_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class WarningPage extends GetView<WarningController> {
  static String routeName = "/WarningPage";
  const WarningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TextWidget(text: "Warnings", textStyle: AppTextStyle.semiBold20),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Markdown(
          data: controller.content,
          selectable: false,
          styleSheet: MarkdownStyleSheet(
            h1: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            p: const TextStyle(fontSize: 15, height: 1.6),
            listBullet: const TextStyle(fontSize: 16),
          ),
          onTapLink: (text, href, title) async {
            if (href == null) return;

            final uri = Uri.parse(href);

            if (uri.scheme == 'mailto') {
              // mở Gmail app
              if (!await launchUrl(uri)) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Unable to open email")));
              }
            } else if (uri.scheme == 'zalo') {
              if (!await launchUrl(uri)) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Unable to open Zalo")));
              }
            } else {
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Unable to open link")));
              }
            }
          },
        ),
      ),
    );
  }
}
