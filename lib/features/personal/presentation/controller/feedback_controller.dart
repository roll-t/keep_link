import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum FeedbackType { feedback, bugReport }

class FeedbackController extends GetxController {
  FeedbackController({FeedbackType initialType = FeedbackType.feedback}) {
    selectedType.value = initialType;
  }

  final Rx<FeedbackType> selectedType = FeedbackType.feedback.obs;
  final messageController = TextEditingController();
  final isLoading = false.obs;

  bool get isSignedIn => FirebaseService.currentUser != null;

  String get title => 'Feedback & Bug Report'.tr;

  String get currentHeader =>
      selectedType.value == FeedbackType.feedback ? 'Send Feedback'.tr : 'Report a Bug'.tr;

  String get hint => selectedType.value == FeedbackType.feedback
      ? 'Share your thoughts, suggestions, or ideas...'.tr
      : 'Describe the bug, steps to reproduce, and expected behavior...'.tr;

  String get typeKey => selectedType.value == FeedbackType.feedback ? 'feedback' : 'bug_report';

  String get dailyLimitMessage => selectedType.value == FeedbackType.feedback
      ? 'Today you can send only 1 feedback. Please try again tomorrow.'.tr
      : 'Today you can send only 3 bug reports. Please try again tomorrow.'.tr;

  String get inputHint => selectedType.value == FeedbackType.feedback
      ? 'Your message...'.tr
      : 'Describe the issue...'.tr;

  IconData get actionIcon =>
      selectedType.value == FeedbackType.feedback ? Icons.send_rounded : Icons.bug_report_rounded;

  String get successMessage => selectedType.value == FeedbackType.feedback
      ? 'Feedback sent. Thank you!'.tr
      : 'Bug report sent. Thank you!'.tr;

  void setType(FeedbackType type) {
    if (selectedType.value != type) {
      selectedType.value = type;
    }
  }

  Future<void> submit() async {
    final message = messageController.text.trim();
    if (message.isEmpty || isLoading.value) return;

    if (!isSignedIn) {
      AppToast.showToast(
        'Please sign in to send feedback.'.tr,
        Icons.lock_outline_rounded,
        color: Colors.orange,
      );
      return;
    }

    isLoading.value = true;
    try {
      String finalMessage = message;

      // Đính kèm metadata thiết bị nếu là báo lỗi để hỗ trợ debug
      if (selectedType.value == FeedbackType.bugReport) {
        try {
          final packageInfo = await PackageInfo.fromPlatform();
          final meta =
              '\n\n--- Device Info ---\nApp: ${packageInfo.version}+${packageInfo.buildNumber}\nOS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
          finalMessage += meta;
        } catch (_) {}
      }

      await FirebaseService.submitFeedback(type: typeKey, message: finalMessage);
      Get.back();
      AppToast.showToast(successMessage, Icons.check_circle_rounded, color: Colors.green);
    } on FirebaseException catch (e) {
      if (e.code == 'unauthenticated') {
        AppToast.showToast(
          'Please sign in to send feedback.'.tr,
          Icons.lock_outline_rounded,
          color: Colors.orange,
        );
      } else if (e.code == 'quota-exceeded') {
        AppToast.showToast(dailyLimitMessage, Icons.info_outline_rounded, color: Colors.orange);
      } else {
        AppToast.showToast(
          'Failed to send. Please try again.'.tr,
          Icons.error_outline_rounded,
          color: Colors.red,
        );
      }
    } catch (_) {
      AppToast.showToast(
        'Failed to send. Please try again.'.tr,
        Icons.error_outline_rounded,
        color: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
