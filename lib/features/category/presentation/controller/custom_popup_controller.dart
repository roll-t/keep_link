import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/data/models/item_model.dart';
import 'package:keep_link/core/utils/utils.dart';

class CustomPopupController extends GetxController {
  final double itemHeight = 50;
  final int maxItemDisplay = 6;
  final RxList<ItemModel> items = <ItemModel>[].obs;
  final Rx<ItemModel?> selectedItem = Rx<ItemModel?>(null);
  final ScrollController scrollController = ScrollController();
  final RxBool isOpen = false.obs;
  // RxBool (not a plain field) so the popup's lock icons refresh immediately
  // when Category Security is toggled in Settings — SecurityMethodController
  // updates this on an already-live CustomPopupController instance, and a
  // plain field write wouldn't trigger the Obx that renders the dropdown.
  final RxBool isEnableSecurity = false.obs;

  @override
  void onInit() {
    super.onInit();
    isEnableSecurity.value = AppGetStorage.isCategorySecurity();
  }

  Future<void> selectItem(ItemModel item) async {
    if (item.visibility == VisibilityStatus.private && AppGetStorage.isCategorySecurity()) {
      final bool isAuth = await Utils.verifySecurity();
      if (!isAuth) return;
    }
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
