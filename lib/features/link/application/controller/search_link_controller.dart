import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/local_storage/sql_lite.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/link/data/model/link_model.dart';

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
      final rows = await DbHelper.getAll('links');

      final searchKey = Utils.removeDiacritics(trimmedQuery);

      final List<LinkModel> allLinks = rows
          .map((row) => LinkModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      final filtered = allLinks.where((item) {
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
