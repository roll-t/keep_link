// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:keep_link/features/link/application/model/meta_data_model.dart';
import 'package:keep_link/features/link/application/model/tiktok_meta_data.dart';
import 'package:tiktok_scraper/tiktok_scraper.dart';

/// Loads preview metadata without depending on a page, route or dialog.
class LinkMetadataService {
  LinkMetadataService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      },
      followRedirects: true,
      maxRedirects: 5,
    ),
  );

  static Future<MetaDataModel> fetch(String url) async {
    try {
      if (_isTikTokUrl(url)) return await _fetchTikTokMeta(url);
      if (_isGoogleMapsUrl(url)) return _extractGoogleMapsMeta(url);
      return await _fetchNormalMeta(url);
    } catch (error, stackTrace) {
      log('Link metadata error: $error', stackTrace: stackTrace);
      return empty(url);
    }
  }

  static MetaDataModel empty(String url) => MetaDataModel(
    url: url,
    title: '',
    description: '',
    imageUrl: '',
    favicon: '',
    appleIcon: '',
  );

  static bool _isTikTokUrl(String url) => url.contains('tiktok.com');

  static bool _isGoogleMapsUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('maps.google.com') ||
        lower.contains('google.com/maps') ||
        lower.contains('maps.app.goo.gl') ||
        lower.contains('goo.gl/maps');
  }

  static MetaDataModel _extractGoogleMapsMeta(String url) {
    var address = '';
    var title = '';
    try {
      final uri = Uri.parse(url);
      final placeIndex = uri.pathSegments.indexOf('place');
      if (placeIndex != -1 && placeIndex + 1 < uri.pathSegments.length) {
        title = Uri.decodeComponent(
          uri.pathSegments[placeIndex + 1],
        ).replaceAll('+', ' ');
        address = title;
      }
      final query = uri.queryParameters['q'];
      if (query != null && query.isNotEmpty) {
        if (title.isEmpty) title = query;
        address = query;
      }
      if (address.isEmpty) {
        final match = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(url);
        if (match != null) address = '${match.group(1)},${match.group(2)}';
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

  static Future<MetaDataModel> _fetchTikTokMeta(String url) async {
    try {
      final endpoint = Uri.parse(
        'https://www.tiktok.com/oembed',
      ).replace(queryParameters: {'url': url}).toString();
      final response = await _dio.get(endpoint);
      if (response.statusCode == 200 && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
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

    try {
      final video = await TiktokScraper.getVideoInfo(url);
      return TiktokMetaData.fromJson(
        video.toMap(),
      ).toMetaData().copyWith(url: url);
    } catch (_) {
      return _fetchNormalMeta(url);
    }
  }

  static Future<MetaDataModel> _fetchNormalMeta(String url) async {
    try {
      final response = await _dio.get(url);
      if (response.statusCode != 200) return empty(url);
      final document = html_parser.parse(response.data);
      return MetaDataModel.fromMap(_parseMetadata(document, url));
    } catch (_) {
      return empty(url);
    }
  }

  static Map<String, dynamic> _parseMetadata(Document document, String url) {
    String? title;
    String? description;
    String? image;
    String? favicon;
    String? appleIcon;
    String? streetAddress;
    String? locality;
    String? region;
    final uriBase = Uri.parse(url);

    String resolveUrl(String? path) {
      if (path == null || path.isEmpty) return '';
      try {
        return uriBase.resolve(path).toString();
      } catch (_) {
        return path;
      }
    }

    bool isUsefulDescription(String text) {
      final normalized = text.toLowerCase();
      return text.length >= 10 &&
          !normalized.contains('nguồn:') &&
          !normalized.contains('source:');
    }

    for (final meta in document.getElementsByTagName('meta')) {
      final property = meta.attributes['property'] ?? meta.attributes['name'];
      final content = meta.attributes['content'];
      if (content == null || content.isEmpty) continue;

      switch (property) {
        case 'og:title':
        case 'twitter:title':
        case 'title':
          title ??= content;
          break;
        case 'og:description':
        case 'twitter:description':
        case 'description':
          if (isUsefulDescription(content)) description ??= content;
          break;
        case 'og:image':
        case 'twitter:image':
          image ??= content;
          break;
        case 'og:street-address':
          streetAddress ??= content;
          break;
        case 'og:locality':
          locality ??= content;
          break;
        case 'og:region':
          region ??= content;
          break;
      }
    }

    for (final link in document.getElementsByTagName('link')) {
      final rel = (link.attributes['rel'] ?? '').toLowerCase();
      final href = link.attributes['href'];
      if (href == null || href.isEmpty) continue;
      if (rel.contains('apple-touch-icon')) appleIcon ??= href;
      if (rel.contains('icon')) favicon ??= href;
      if (rel.contains('image_src')) image ??= href;
    }

    if (title == null || title.isEmpty) {
      final tags = document.getElementsByTagName('title');
      if (tags.isNotEmpty) title = tags.first.text;
    }

    if (streetAddress == null && locality == null) {
      for (final script in document.getElementsByTagName('script')) {
        if (script.attributes['type'] != 'application/ld+json') continue;
        try {
          final raw = jsonDecode(script.text);
          final candidates = raw is List ? raw : [raw];
          for (final candidate in candidates) {
            if (candidate is! Map) continue;
            final data = Map<String, dynamic>.from(candidate);
            final address = data['address'];
            if (address is Map) {
              final map = Map<String, dynamic>.from(address);
              streetAddress ??= map['streetAddress'] as String?;
              locality ??= map['addressLocality'] as String?;
              region ??= map['addressRegion'] as String?;
            }
          }
        } catch (_) {}
      }
    }

    final address = [
      streetAddress,
      locality,
      region,
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');

    return {
      'URL': url,
      'TITLE': title?.trim() ?? '',
      'DESCRIPTION': description?.trim() ?? '',
      'IMAGE_URL': resolveUrl(image),
      'FAVICON': resolveUrl(favicon),
      'APPLE_ICON': resolveUrl(appleIcon),
      'ADDRESS': address,
    };
  }
}
