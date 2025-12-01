// ignore_for_file: depend_on_referenced_packages

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:keep_link/core/utils/mixin/argument_handle_mixin_controller.dart';
import 'package:keep_link/features/link/data/model/meta_data_model.dart';
import 'package:keep_link/features/link/data/model/tiktok_meta_data.dart';
import 'package:keep_link/features/splash/presentation/controller/splash_controller.dart';
import 'package:tiktok_scraper/tiktok_scraper.dart';

class DeepLinkController extends GetxController with ArgumentHandlerMixinController<SplashArg> {
  final Rx<MetaDataModel?> metaData = Rx(null);
  final RxBool isLoading = false.obs;
  String? deepLink; // Bỏ late final để tránh lỗi runtime nếu access sớm

  // Singleton Dio instance để tối ưu performance
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        "User-Agent": "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
        // Hoặc giả lập browser
        // "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36..."
      },
      followRedirects: true,
      maxRedirects: 5,
    ),
  );

  @override
  void onInit() {
    super.onInit();
    if (handleArgumentFromGet()) {
      _initDeepLink();
    }
  }

  void _initDeepLink() {
    deepLink = argsData?.deepLinkText;
    if (deepLink == null || deepLink!.isEmpty) return;
    fetchMetaData(deepLink!);
  }

  Future<void> fetchMetaData(String url) async {
    isLoading.value = true;
    update(["EXTRA_LINK_ID"]); // Trigger GetBuilder loading state

    try {
      if (_isTikTokUrl(url)) {
        metaData.value = await _fetchTikTokMeta(url);
      } else {
        metaData.value = await _fetchNormalMeta(url);
      }
    } catch (e) {
      print("Error fetching metadata: $e");
    } finally {
      isLoading.value = false;
      update(["EXTRA_LINK_ID"]); // Trigger GetBuilder render UI
    }
  }

  bool _isTikTokUrl(String url) => url.contains("tiktok.com");

  Future<MetaDataModel?> _fetchTikTokMeta(String url) async {
    try {
      final video = await TiktokScraper.getVideoInfo(url);
      final parsed = TiktokMetaData.fromJson(video.toMap());
      return parsed.toMetaData().copyWith(url: url);
    } catch (e) {
      // Fallback sang normal meta nếu API tiktok lỗi
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

    // Helper function để resolve URL tương đối thành tuyệt đối
    // Ví dụ: /img/logo.png -> https://domain.com/img/logo.png
    String resolveUrl(String? path) {
      if (path == null || path.isEmpty) return '';
      try {
        return uriBase.resolve(path).toString();
      } catch (e) {
        return path;
      }
    }

    // 1. Quét thẻ META
    for (var meta in doc.getElementsByTagName("meta")) {
      final property =
          meta.attributes["property"] ?? meta.attributes["name"]; // Hỗ trợ cả property và name
      final content = meta.attributes["content"];

      if (content == null || content.isEmpty) continue;

      if (property == "og:title" || property == "title") title = content;
      if (property == "og:description" || property == "description") description = content;
      if (property == "og:image") image = content;
    }

    // 2. Quét thẻ LINK (Icon)
    for (var link in doc.getElementsByTagName("link")) {
      final rel = link.attributes['rel'];
      final href = link.attributes['href'];
      if (href == null) continue;

      if (rel == 'apple-touch-icon') appleIcon = href;
      if (rel?.contains('icon') == true) favicon = href;
    }

    // 3. Fallback Title
    if (title == null || title.isEmpty) {
      final titleTags = doc.getElementsByTagName("title");
      if (titleTags.isNotEmpty) {
        title = titleTags.first.text;
      }
    }

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
