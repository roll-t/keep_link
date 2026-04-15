// ignore_for_file: depend_on_referenced_packages

import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/core/utils/mixin/argument_handle_mixin_controller.dart';
import 'package:keep_link/features/link/application/model/meta_data_model.dart';
import 'package:keep_link/features/link/application/model/tiktok_meta_data.dart';
import 'package:keep_link/features/splash/presentation/controller/splash_controller.dart';
import 'package:tiktok_scraper/tiktok_scraper.dart';

class DeepLinkController extends GetxController with ArgumentHandlerMixinController<SplashArg> {
  final Rx<MetaDataModel?> metaData = Rx(null);
  final RxBool isLoading = false.obs;
  String? deepLink;
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
      },
      followRedirects: true,
      maxRedirects: 5,
    ),
  );

  @override
  void onInit() {
    super.onInit();
    if (handleArgumentFromGet()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initDeepLink();
      });
    }
  }

  void _initDeepLink() {
    deepLink = argsData?.deepLinkText;
    if (deepLink == null || deepLink!.isEmpty) return;
    fetchMetaData(deepLink!);
  }

  Future<void> fetchMetaData(String url) async {
    isLoading.value = true;
    await Future.delayed(Duration(milliseconds: 50));
    DialogUtils.showProgressDialog();
    update(["EXTRA_LINK_ID"]);
    try {
      if (_isTikTokUrl(url)) {
        metaData.value = await _fetchTikTokMeta(url);
      } else {
        metaData.value = await _fetchNormalMeta(url);
      }
    } catch (e) {
      log("Error fetching metadata: $e");
    } finally {
      isLoading.value = false;
      update(["EXTRA_LINK_ID"]);
      Get.back();
    }
  }

  bool _isTikTokUrl(String url) => url.contains("tiktok.com");

  Future<MetaDataModel?> _fetchTikTokMeta(String url) async {
    try {
      final video = await TiktokScraper.getVideoInfo(url);
      final parsed = TiktokMetaData.fromJson(video.toMap());
      return parsed.toMetaData().copyWith(url: url);
    } catch (e) {
      return await _fetchNormalMeta(url);
    }
  }

  Future<MetaDataModel?> _fetchNormalMeta(String url) async {
    try {
      final document = await _fetchDocument(url);
      if (document == null) {
        return MetaDataModel(
          url: url,
          title: "",
          description: "",
          imageUrl: "",
          favicon: '',
          appleIcon: '',
        );
      }

      return MetaDataModel.fromMap(_parseMetadata(document, url));
    } catch (e) {
      return MetaDataModel(
        url: url,
        title: "",
        description: "",
        imageUrl: "",
        favicon: '',
        appleIcon: '',
      );
    }
  }

  Future<Document?> _fetchDocument(String url) async {
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        return html_parser.parse(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> _parseMetadata(Document doc, String url) {
    String? title, description, image, favicon, appleIcon;

    final uriBase = Uri.parse(url);

    // Resolve URL tương đối thành URL tuyệt đối
    String resolveUrl(String? path) {
      if (path == null || path.isEmpty) return '';
      try {
        return uriBase.resolve(path).toString();
      } catch (e) {
        return path;
      }
    }

    bool isJunkDescription(String text) {
      final t = text.toLowerCase();
      return t.startsWith("nguồn:") ||
          t.contains("nguồn:") ||
          t.contains("source:") ||
          t.length < 10;
    }

    // ===========================
    // 1. META TAGS
    // ===========================
    for (var meta in doc.getElementsByTagName("meta")) {
      final property = meta.attributes["property"] ?? meta.attributes["name"];
      final content = meta.attributes["content"];

      if (content == null || content.isEmpty) continue;

      switch (property) {
        case "og:title":
          title ??= content;
          break;

        case "twitter:title":
          title ??= content;
          break;

        case "title":
          title ??= content;
          break;

        case "og:description":
          if (!isJunkDescription(content)) {
            description = content;
          }
          break;

        case "twitter:description":
          if (!isJunkDescription(content)) {
            description ??= content;
          }
          break;

        case "description":
          if (!isJunkDescription(content)) {
            description ??= content;
          }
          break;

        case "og:image":
          image ??= content;
          break;

        case "twitter:image":
          image ??= content;
          break;
      }
    }

    // ===========================
    // 2. LINK TAGS → favicon + apple-icon
    // ===========================
    for (var link in doc.getElementsByTagName("link")) {
      final rel = (link.attributes['rel'] ?? '').toLowerCase();
      final href = link.attributes['href'];
      if (href == null) continue;

      if (rel == 'apple-touch-icon' || rel.contains('apple-touch-icon')) {
        appleIcon ??= href;
      }

      if (rel.contains('icon')) {
        favicon ??= href;
      }

      if (rel.contains('shortcut icon')) {
        favicon ??= href;
      }

      if (rel.contains('image_src')) {
        image ??= href;
      }
    }

    // ===========================
    // 3. Fallback Title
    // ===========================
    if (title == null || title.isEmpty) {
      final tags = doc.getElementsByTagName("title");
      if (tags.isNotEmpty) {
        title = tags.first.text;
      }
    }

    // ===========================
    // 4. Kết quả cuối cùng
    // ===========================
    return {
      'URL': url,
      'TITLE': title ?? '',
      'DESCRIPTION': description ?? '',
      'IMAGE_URL': resolveUrl(image),
      'FAVICON': resolveUrl(favicon),
      'APPLE_ICON': resolveUrl(appleIcon),
    };
  }
}
