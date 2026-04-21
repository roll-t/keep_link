import 'package:get/get.dart';
import 'package:keep_link/features/personal/presentation/controller/feedback_controller.dart';

class FeedbackBinding extends Bindings {
  FeedbackBinding({required this.type});

  final FeedbackType type;

  @override
  void dependencies() {
    Get.put<FeedbackController>(FeedbackController(type: type));
  }
}
