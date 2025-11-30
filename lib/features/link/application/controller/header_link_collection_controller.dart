import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/ui/popup/custom_popup_controller.dart';

class HeaderLinkCollectionController extends GetxController {
  final CustomPopupController popupController = Get.put(CustomPopupController());
  final linkController = TextEditingController();
}
