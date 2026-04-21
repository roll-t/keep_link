import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';

class AppToast {
  static void showToast(String msg, IconData icon, {Color color = AppColors.n300}) {
    final ctx = Get.key.currentContext;
    if (ctx == null) return;
    FToast()
      ..init(ctx)
      ..showToast(
        gravity: ToastGravity.BOTTOM,
        toastDuration: const Duration(seconds: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: TextWidget(text: msg, color: Colors.white, size: 14, maxLines: 2),
              ),
            ],
          ),
        ),
      );
  }
}
