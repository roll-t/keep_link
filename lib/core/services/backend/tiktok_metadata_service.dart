import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:keep_link/features/link/application/model/meta_data_model.dart';

/// Fetches public TikTok post metadata through TikTok's official oEmbed API.
///
/// Short share links are resolved first because oEmbed is most reliable with
/// the canonical `www.tiktok.com/@user/video/id` URL.
class TikTokMetadataService {
  TikTokMetadataService._();

  static const _oEmbedUrl = 'https://www.tiktok.com/oembed';
  static const _shortLinkHosts = {'vm.tiktok.com', 'vt.tiktok.com'};

  static bool isTikTokUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return false;
    }
    final host = uri.host.toLowerCase();
    return host == 'tiktok.com' || host.endsWith('.tiktok.com');
  }

  static Future<MetaDataModel?> fetch(String url, {required Dio client}) async {
    if (!isTikTokUrl(url)) return null;

    var metadataUrl = _withoutTrackingParameters(url);
    if (_needsRedirectResolution(url)) {
      final resolvedUrl = await _resolveShortLink(url, client);
      if (resolvedUrl != null) {
        metadataUrl = _withoutTrackingParameters(resolvedUrl);
      }
    }

    final results = await Future.wait<Object?>([
      _fetchOEmbed(metadataUrl, client),
      _fetchAddress(metadataUrl, client).timeout(const Duration(seconds: 4), onTimeout: () => ''),
    ]);
    final result = results[0] as MetaDataModel?;
    final address = results[1] as String? ?? '';
    if (result != null) {
      return result.copyWith(url: url, address: address);
    }
    return null;
  }

  static Future<String?> _resolveShortLink(String url, Dio client) async {
    final headResult = await _followRedirects(url, client, useHead: true);
    if (headResult != null) return headResult;
    return _followRedirects(url, client, useHead: false);
  }

  static Future<String?> _followRedirects(String url, Dio client, {required bool useHead}) async {
    try {
      final options = Options(
        method: useHead ? 'HEAD' : 'GET',
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status < 400,
      );
      final response = await client.request<dynamic>(url, options: options);
      final resolved = response.realUri.toString();
      return isTikTokUrl(resolved) ? resolved : null;
    } catch (_) {
      return null;
    }
  }

  static bool _needsRedirectResolution(String url) {
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();
    return _shortLinkHosts.contains(host) ||
        (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 't');
  }

  static String _withoutTrackingParameters(String url) {
    final fragmentIndex = url.indexOf('#');
    final withoutFragment = fragmentIndex == -1 ? url : url.substring(0, fragmentIndex);
    final queryIndex = withoutFragment.indexOf('?');
    return queryIndex == -1 ? withoutFragment : withoutFragment.substring(0, queryIndex);
  }

  static Future<MetaDataModel?> _fetchOEmbed(String url, Dio client) async {
    try {
      final response = await client.get<dynamic>(_oEmbedUrl, queryParameters: {'url': url});
      if (response.statusCode != 200 || response.data is! Map) return null;

      final data = Map<String, dynamic>.from(response.data as Map);
      final title = data['title']?.toString().trim() ?? '';
      final thumbnail = data['thumbnail_url']?.toString().trim() ?? '';
      final author = data['author_name']?.toString().trim() ?? '';
      if (title.isEmpty && thumbnail.isEmpty && author.isEmpty) return null;

      return MetaDataModel(
        url: url,
        title: title.isNotEmpty ? title : author,
        description: author.isNotEmpty ? author : '',
        imageUrl: thumbnail,
        favicon: '',
        appleIcon: '',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String> _fetchAddress(String url, Dio client) async {
    try {
      final response = await client.get<dynamic>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      if (response.statusCode != 200 || response.data is! String) return '';
      return _extractAddress(response.data as String);
    } catch (_) {
      return '';
    }
  }

  static String _extractAddress(String html) {
    try {
      final document = html_parser.parse(html);
      Map<String, dynamic>? item;

      final rehydrationScript = document.getElementById('__UNIVERSAL_DATA_FOR_REHYDRATION__');
      if (rehydrationScript != null && rehydrationScript.text.trim().isNotEmpty) {
        final root = jsonDecode(rehydrationScript.text);
        final scope = _mapAt(root, '__DEFAULT_SCOPE__');
        final detail = _mapAt(scope, 'webapp.video-detail');
        final info = _mapAt(detail, 'itemInfo');
        item = _mapAt(info, 'itemStruct');
      }

      // TikTok serves Android/mobile user agents a different document. Its
      // post data lives in `script#api-data` instead of the rehydration state.
      if (item == null) {
        final apiDataScript = document.getElementById('api-data');
        if (apiDataScript != null && apiDataScript.text.trim().isNotEmpty) {
          final root = jsonDecode(apiDataScript.text);
          final detail = _mapAt(root, 'videoDetail');
          final info = _mapAt(detail, 'itemInfo');
          item = _mapAt(info, 'itemStruct');
        }
      }
      if (item == null) return '';

      final contentLocation = _mapAt(item, 'contentLocation');
      final contentAddress = contentLocation == null ? null : _mapAt(contentLocation, 'address');
      final streetAddress = _stringAt(contentAddress, 'streetAddress');
      if (streetAddress.isNotEmpty) return streetAddress;

      final structuredAddress = [
        _stringAt(contentAddress, 'addressLocality'),
        _stringAt(contentAddress, 'addressRegion'),
        _stringAt(contentAddress, 'addressCountry'),
      ].where((part) => part.isNotEmpty).join(', ');
      if (structuredAddress.isNotEmpty) return structuredAddress;

      final poi = _mapAt(item, 'poi');
      final poiName = _stringAt(poi, 'name');
      final poiAddress = _stringAt(poi, 'address');
      if (poiAddress.isEmpty) return poiName;
      if (poiName.isEmpty || poiAddress.toLowerCase().contains(poiName.toLowerCase())) {
        return poiAddress;
      }
      return '$poiName, $poiAddress';
    } catch (_) {
      return '';
    }
  }

  static Map<String, dynamic>? _mapAt(dynamic value, String key) {
    if (value is! Map) return null;
    final child = value[key];
    if (child is! Map) return null;
    return Map<String, dynamic>.from(child);
  }

  static String _stringAt(Map<String, dynamic>? value, String key) {
    final result = value?[key];
    return result is String ? result.trim() : '';
  }
}
