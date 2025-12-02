import 'dart:developer';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/local_storage/sql_lite.dart';
import 'package:keep_link/features/link/data/model/link_model.dart';

class LinkCollectionController extends GetxController {
  final RxList<LinkModel> listLink = <LinkModel>[].obs;

  @override
  onInit() async {
    super.onInit();
    await fetchAllLinks();
  }

  /// Lấy tất cả link từ DB
  Future<void> fetchAllLinks() async {
    try {
      final rows = await DbHelper.getAll('links');
      final links = rows.map((row) {
        return LinkModel.fromJson(Map<String, dynamic>.from(row));
      }).toList();
      listLink.assignAll(links);
    } catch (e) {
      log('Error fetching links: $e');
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
