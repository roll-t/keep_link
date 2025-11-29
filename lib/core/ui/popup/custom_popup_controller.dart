import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/model/item_model.dart';

class CustomPopupController extends GetxController {
  final double itemHeight = 50;
  final RxList<ItemModel> items = <ItemModel>[].obs;
  final Rx<ItemModel?> selectedItem = Rx<ItemModel?>(null);

  final ScrollController scrollController = ScrollController();
  final RxBool isOpen = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  void loadItems() {
    items.assignAll(
      List.generate(
        30,
        (i) => ItemModel(id: "$i", name: "Item hkdajsd ashdkjahsdkjhahskdj askjd áhdkjash$i"),
      ),
    );

    selectedItem.value = items.first;
  }

  void selectItem(ItemModel item) {
    selectedItem.value = item;
  }

  /// Auto scroll đến item đang chọn khi pop mở lại
  void scrollToSelected() {
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
}
