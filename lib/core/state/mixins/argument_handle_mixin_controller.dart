import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

mixin ArgumentHandlerMixinController<T> on GetxController {
  T? argsData;

  /// Getter an toàn (nullable)
  T? get argumentOrNull => argsData;

  /// Getter bắt buộc có args, nếu không sẽ throw
  T get requireArgument {
    if (argsData == null) {
      throw StateError('Argument has not been set or failed to parse.');
    }
    return argsData!;
  }

  /// Gán argument thủ công
  bool handleArgument(Object? args) {
    if (args is T) {
      argsData = args;
      return true;
    }
    return false;
  }

  /// Gán argument từ Get.arguments
  bool handleArgumentFromGet() {
    return handleArgument(Get.arguments);
  }

  /// Điều hướng và truyền argument
  void navigateWithArgument(String routeName, Object argument) {
    Get.toNamed(routeName, arguments: argument);
  }

  /// Dọn dẹp argument
  @mustCallSuper
  void disposeArgumentHandler() {
    argsData = null;
    log("🧹 [ArgumentHandlerMixin] Disposed");
  }
}
