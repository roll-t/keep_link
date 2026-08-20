import 'package:get/get.dart';
import 'package:keep_link/features/personal/presentation/controller/feedback_controller.dart';

class FeedbackBinding extends Bindings {
  FeedbackBinding({this.type = FeedbackType.feedback});

  final FeedbackType type;

  @override
  void dependencies() {
    Get.lazyPut<FeedbackController>(() => FeedbackController(initialType: type));
  }
}
