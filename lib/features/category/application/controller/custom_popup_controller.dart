import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/model/item_model.dart';

class CustomPopupController extends GetxController {
  final double itemHeight = 50;
  final int maxItemDisplay = 6;
  final RxList<ItemModel> items = <ItemModel>[].obs;
  final Rx<ItemModel?> selectedItem = Rx<ItemModel?>(null);
  final ScrollController scrollController = ScrollController();
  final RxBool isOpen = false.obs;
  void selectItem(ItemModel item) {
    selectedItem.value = item;
  }

  /// Auto scroll đến item đang chọn khi pop mở lại
  void scrollToSelected() {
    if (items.length <= maxItemDisplay) return;
    final index = items.indexWhere((e) => e.id == selectedItem.value?.id);
    if (index >= 0) {
      Future.delayed(const Duration(milliseconds: 200), () {
        scrollController.animateTo(
          index * itemHeight,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
        );
      });
    }
  }

  ItemModel? getItemById(String id) {
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
