// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
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
    await Future.delayed(const Duration(milliseconds: 50));
    DialogUtils.showProgressDialog();
    update(["EXTRA_LINK_ID"]);
    try {
      if (_isTikTokUrl(url)) {
        metaData.value = await _fetchTikTokMeta(url);
      } else if (_isGoogleMapsUrl(url)) {
        metaData.value = _extractGoogleMapsMeta(url);
      } else {
        metaData.value = await _fetchNormalMeta(url);
      }
    } catch (e) {
      log("Error fetching metadata: $e");
      metaData.value = MetaDataModel(
        url: url,
        title: '',
        description: '',
        imageUrl: '',
        favicon: '',
        appleIcon: '',
      );
    } finally {
      isLoading.value = false;
      update(["EXTRA_LINK_ID"]);
      Get.back();
    }
  }

  bool _isTikTokUrl(String url) => url.contains("tiktok.com");

  bool _isGoogleMapsUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('maps.google.com') ||
        lower.contains('google.com/maps') ||
        lower.contains('maps.app.goo.gl') ||
        lower.contains('goo.gl/maps');
  }

  MetaDataModel _extractGoogleMapsMeta(String url) {
    String address = '';
    String title = '';
    try {
      final uri = Uri.parse(url);
      // Place name from path: /maps/place/PlaceName/@lat,lng
      final pathSegments = uri.pathSegments;
      final placeIdx = pathSegments.indexOf('place');
      if (placeIdx != -1 && placeIdx + 1 < pathSegments.length) {
        title = Uri.decodeComponent(pathSegments[placeIdx + 1]).replaceAll('+', ' ');
        address = title;
      }
      // ?q=address
      final q = uri.queryParameters['q'];
      if (q != null && q.isNotEmpty) {
        if (title.isEmpty) title = q;
        address = q;
      }
      // lat,lng from @lat,lng in path
      if (address.isEmpty) {
        final m = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(url);
        if (m != null) address = '${m.group(1)},${m.group(2)}';
      }
    } catch (_) {}
    return MetaDataModel(
      url: url,
      title: title.isNotEmpty ? title : 'Google Maps',
      description: '',
      imageUrl: '',
      favicon: '',
      appleIcon: '',
      address: address,
    );
  }

  Future<MetaDataModel?> _fetchTikTokMeta(String url) async {
    // 1. Thử TikTok oEmbed API chính thức (ít bị block nhất)
    try {
      final oembedUrl = Uri.parse(
        'https://www.tiktok.com/oembed',
      ).replace(queryParameters: {'url': url}).toString();
      final response = await _dio.get(oembedUrl);
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final title = data['title'] as String? ?? '';
        final thumbnail = data['thumbnail_url'] as String? ?? '';
        final author = data['author_name'] as String? ?? '';
        return MetaDataModel(
          url: url,
          title: title.isNotEmpty ? title : author,
          description: author.isNotEmpty ? '@$author' : '',
          imageUrl: thumbnail,
          favicon: '',
          appleIcon: '',
        );
      }
    } catch (_) {}

    // 2. Fallback: tiktok_scraper
    try {
      final video = await TiktokScraper.getVideoInfo(url);
      final parsed = TiktokMetaData.fromJson(video.toMap());
      return parsed.toMetaData().copyWith(url: url);
    } catch (_) {}

    // 3. Fallback cuối: parse HTML thông thường
    return await _fetchNormalMeta(url);
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
    String? streetAddress, locality, region;

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
      return t.contains("nguồn:") || t.contains("source:") || t.length < 10;
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

        case "og:street-address":
          streetAddress ??= content;
          break;

        case "og:locality":
          locality ??= content;
          break;

        case "og:region":
          region ??= content;
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
    // 4. JSON-LD (LocalBusiness / Place)
    // ===========================
    if (streetAddress == null && locality == null) {
      for (final script in doc.getElementsByTagName('script')) {
        if (script.attributes['type'] != 'application/ld+json') continue;
        try {
          final raw = jsonDecode(script.text);
          void tryExtract(Map<String, dynamic> data) {
            final type = data['@type'];
            final placeTypes = [
              'LocalBusiness',
              'Place',
              'Restaurant',
              'FoodEstablishment',
              'CivicStructure',
              'TouristAttraction',
              'Hotel',
              'Store',
              'Accommodation',
              'LodgingBusiness',
            ];
            final isPlace =
                (type is String && placeTypes.any((t) => type.contains(t))) ||
                (type is List &&
                    placeTypes.any((t) => (type).any((ty) => ty.toString().contains(t))));
            if (!isPlace) return;
            final addr = data['address'];
            if (addr is Map<String, dynamic>) {
              streetAddress ??= addr['streetAddress'] as String?;
              locality ??= addr['addressLocality'] as String?;
              region ??= addr['addressRegion'] as String?;
            } else if (addr is String && addr.isNotEmpty) {
              streetAddress ??= addr;
            }
          }

          if (raw is Map<String, dynamic>) {
            tryExtract(raw);
          } else if (raw is List) {
            for (final item in raw) {
              if (item is Map<String, dynamic>) tryExtract(item);
            }
          }
        } catch (_) {}
      }
    }

    final addressParts = [
      streetAddress,
      locality,
      region,
    ].where((p) => p != null && p.isNotEmpty).toList();
    final address = addressParts.join(', ');

    // ===========================
    // 5. Kết quả cuối cùng
    // ===========================
    return {
      'URL': url,
      'TITLE': title ?? '',
      'DESCRIPTION': description ?? '',
      'IMAGE_URL': resolveUrl(image),
      'FAVICON': resolveUrl(favicon),
      'APPLE_ICON': resolveUrl(appleIcon),
      'ADDRESS': address,
    };
  }
}
