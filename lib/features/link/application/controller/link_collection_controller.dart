import 'dart:developer';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/local_storage/sql_lite.dart';
import 'package:keep_link/core/ui/popup/custom_popup_controller.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/features/link/data/model/link_model.dart';

class LinkCollectionController extends GetxController {
  final RxList<LinkModel> listLink = <LinkModel>[].obs;

  @override
  onInit() async {
    super.onInit();
    await fetchAllLinks();
  }

  /// Lấy tất cả link từ DB, nhưng chỉ lấy theo category đang chọn
  Future<void> fetchAllLinks() async {
    final CustomPopupController categoryCustomPopup = Get.find<CustomPopupController>();
    try {
      final categoryId = categoryCustomPopup.selectedItem.value?.id;
      final rows = await DbHelper.getAll('links');
      final links =
          (categoryId == 'all' || categoryId == null
                  ? rows
                  : rows.where((row) => row['categoryId'] == categoryId))
              .map((row) => LinkModel.fromJson(Map<String, dynamic>.from(row)))
              .toList();
      listLink.assignAll(links);

      log('Fetched ${links.length} links for category $categoryId');
    } catch (e) {
      log('Error fetching links: $e');
    }
  }

  Future<void> onDeleteLink(String id) async {
    try {
      DialogUtils.showConfirm(
        alertType: AlertType.warning,
        title: "Xác nhận",
        content: "Bạn chắc chắn muốn xóa link!",
        onConfirm: () async {
          await DbHelper.delete('links', id);
          listLink.removeWhere((item) => item.id == id);
          Get.back();
          Get.back();
          Fluttertoast.showToast(msg: "Đã xóa");
          log("Deleted link with id: $id");
        },
        onCancel: () {
          Get.back();
        },
      );
    } catch (e) {
      log("Error deleting link: $e");
      Fluttertoast.showToast(msg: "Delete failed");
    }
  }

  /// Xóa list trong controller
  void clearLinks() {
    listLink.clear();
  }

  Future<void> onRefreshData() async {
    try {
      await fetchAllLinks();
      Fluttertoast.showToast(msg: "Refreshed");
      log('Link data has been refreshed.');
    } catch (e) {
      log('Error refreshing data: $e');
    }
  }
}
