import 'package:get/get.dart';
import 'package:keep_link/features/splash/presentation/controller/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController());
  }
}
