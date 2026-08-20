import 'package:get/get.dart';

class DependencyUtils {
  /// Put dependency immediately if it is not registered yet
  static T put<T extends Object>(T Function() builder, {bool permanent = false}) {
    if (!Get.isRegistered<T>()) {
      return Get.put<T>(builder(), permanent: permanent);
    } else {
      return Get.find<T>();
    }
  }

  /// Put dependency lazily if it is not registered yet
  static void lazyPut<T extends Object>(T Function() builder, {bool fenix = false}) {
    if (!Get.isRegistered<T>()) {
      Get.lazyPut<T>(builder, fenix: fenix);
    }
  }

  static void removeByType(Type type) {
    final tag = type.toString();
    if (Get.isRegistered(tag: tag)) {
      Get.delete(tag: tag, force: true);
    }
  }

  /// Find dependency safely, nếu chưa có sẽ trả về null
  static T? find<T extends Object>() {
    if (Get.isRegistered<T>()) {
      return Get.find<T>();
    }
    return null;
  }

  /// Find dependency với tag nếu cần
  static T? findByTag<T extends Object>(String tag) {
    if (Get.isRegistered<T>(tag: tag)) {
      return Get.find<T>(tag: tag);
    }
    return null;
  }
}
