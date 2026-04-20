import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/service/firebase_service.dart';
import 'package:keep_link/core/utils/app_toast.dart';

enum FeedbackType { feedback, bugReport }

class FeedbackController extends GetxController {
  FeedbackController({required this.type});

  final FeedbackType type;
  final messageController = TextEditingController();
  final isLoading = false.obs;

  String get title => type == FeedbackType.feedback ? 'Send Feedback'.tr : 'Report a Bug'.tr;

  String get hint => type == FeedbackType.feedback
      ? 'Share your thoughts, suggestions, or ideas...'.tr
      : 'Describe the bug, steps to reproduce, and expected behavior...'.tr;

  String get typeKey => type == FeedbackType.feedback ? 'feedback' : 'bug_report';

  String get dailyLimitMessage => type == FeedbackType.feedback
      ? 'Today you can send only 1 feedback. Please try again tomorrow.'.tr
      : 'Today you can send only 3 bug reports. Please try again tomorrow.'.tr;

  String get inputHint =>
      type == FeedbackType.feedback ? 'Your message...'.tr : 'Describe the issue...'.tr;

  IconData get actionIcon =>
      type == FeedbackType.feedback ? Icons.send_rounded : Icons.bug_report_rounded;

  String get successMessage => type == FeedbackType.feedback
      ? 'Feedback sent. Thank you!'.tr
      : 'Bug report sent. Thank you!'.tr;

  Future<void> submit() async {
    final message = messageController.text.trim();
    if (message.isEmpty || isLoading.value) return;

    isLoading.value = true;
    try {
      await FirebaseService.submitFeedback(type: typeKey, message: message);
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
