import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_enum.dart'; // Nơi chứa VisibilityStatus
import 'package:keep_link/core/local_storage/sql_lite.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/data/model/category_model.dart'; // Đổi đường dẫn theo dự án của bạn
import 'package:keep_link/features/link/application/model/link_model.dart';

class SearchLinkController extends GetxController {
  final RxList<LinkModel> searchResults = <LinkModel>[].obs;
  final Rx<TextEditingController> searchTec = TextEditingController().obs;
  final RxString searchText = "".obs;

  @override
  void onInit() {
    super.onInit();
    searchTec.value.addListener(() {
      searchText.value = searchTec.value.text;
      if (searchTec.value.text.isEmpty) {
        searchResults.clear();
      }
    });
    debounce(
      searchText,
      (String value) => searchLinks(value),
      time: const Duration(milliseconds: 500),
    );
  }

  Future<void> searchLinks(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      searchResults.clear();
      return;
    }

    try {
      // =======================================================
      // BƯỚC 1: TÌM CÁC DANH MỤC ĐANG BỊ KHOÁ BẢO MẬT
      // =======================================================
      final categoryRows = await DbHelper.getAll('categories');

      // 👉 THÊM 3 DÒNG LOG NÀY ĐỂ KIỂM TRA DB THỰC TẾ
      for (var row in categoryRows) {
        log("🔍 Debug DB - Tên DM: ${row['name']} | Trạng thái: ${row['visibility']}");
      }

      // Chuyển thành tập hợp (Set) các ID của danh mục không public
      final Set<String> privateCategoryIds = categoryRows
          .map((row) => CategoryModel.fromJson(Map<String, dynamic>.from(row)))
          .where((cat) => cat.visibility != VisibilityStatus.public)
          .map((cat) => cat.id ?? "")
          .toSet();

      log("🚫 Các ID danh mục bị khóa: $privateCategoryIds");
      // =======================================================
      // BƯỚC 2: TÌM KIẾM LINK & LỌC BỎ LINK BẢO MẬT
      // =======================================================
      final rows = await DbHelper.getAll('links');
      final searchKey = Utils.removeDiacritics(trimmedQuery);

      final List<LinkModel> allLinks = rows
          .map((row) => LinkModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();

      final filtered = allLinks.where((item) {
        // CHẶN BẢO MẬT: Nếu link có categoryId nằm trong nhóm private -> Bỏ qua
        if (item.categoryId != null && privateCategoryIds.contains(item.categoryId)) {
          return false;
        }

        // Logic tìm kiếm text
        final title = Utils.removeDiacritics(item.metaDataModel?.title ?? "");
        final note = Utils.removeDiacritics(item.name ?? "");
        final url = (item.metaDataModel?.url ?? "").toLowerCase();

        return title.contains(searchKey) || note.contains(searchKey) || url.contains(searchKey);
      }).toList();

      searchResults.assignAll(filtered);
    } catch (e) {
      log('Lỗi tìm kiếm: $e');
    }
  }

  @override
  void onClose() {
    searchTec.value.dispose();
    super.onClose();
  }
}
