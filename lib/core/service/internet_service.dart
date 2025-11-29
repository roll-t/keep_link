import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';

class InternetService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    _listenNetworkChange();
  }

  void _listenNetworkChange() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      if (results.isNotEmpty) {
        final online = await checkNetwork();
        if (isConnected.value != online) {
          isConnected.value = online;
          showSnackbar(online);
        }
      }
    });

    // check initial state
    Future.microtask(() async {
      isConnected.value = await checkNetwork();
    });
  }

  Future<bool> checkNetwork() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  void showSnackbar(bool online) {
    if (!Get.isSnackbarOpen) {
      if (!online) {
        DialogUtils.showAlert(
          barrierDismissible: false,
          alertType: AlertType.error,
          title: "Lỗi kết nối mạng",
          content: "Vui lòng kiểm tra lại kết nối mạng.",
          confirmText: "Thử lại",
          onConfirm: () async {
            final isOnline = await checkNetwork();
            if (isOnline) {
              Get.back();
              Get.snackbar(
                'Đã kết nối mạng',
                'Kết nối internet đã được khôi phục.',
                snackPosition: SnackPosition.TOP,
                backgroundColor: AppColors.green,
                colorText: AppColors.white,
                duration: const Duration(seconds: 2),
              );
            }
          },
        );
      }
    }
  }
}
