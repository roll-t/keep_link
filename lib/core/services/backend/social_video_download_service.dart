import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SocialVideoDownloadException implements Exception {
  const SocialVideoDownloadException(this.code);

  final String code;
}

class SocialVideoSource {
  const SocialVideoSource({
    required this.url,
    required this.platform,
    this.extension = 'mp4',
    this.requestHeaders = const {},
  });

  final String url;
  final String platform;
  final String extension;
  final Map<String, String> requestHeaders;
}

/// Resolves media URLs that a public page explicitly exposes to the browser.
///
/// This service deliberately does not call watermark-removal services, forge
/// signed URLs, bypass authentication, or support YouTube offline downloads.
class SocialVideoDownloadService {
  SocialVideoDownloadService._();

  static final Dio _client = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      followRedirects: true,
      maxRedirects: 6,
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/122.0 Mobile Safari/537.36',
        'Accept-Language': 'vi-VN,vi;q=0.9,en;q=0.7',
      },
    ),
  );

  static bool supports(String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasAuthority) return false;
    final host = uri.host.toLowerCase();
    return _isDirectVideo(uri) ||
        host == 'tiktok.com' ||
        host.endsWith('.tiktok.com') ||
        host == 'instagram.com' ||
        host.endsWith('.instagram.com') ||
        host == 'youtube.com' ||
        host.endsWith('.youtube.com') ||
        host == 'youtu.be';
  }

  static Future<SocialVideoSource> resolve(String rawUrl, {Dio? client}) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const SocialVideoDownloadException('invalid_url');
    }

    if (_isDirectVideo(uri)) {
      return SocialVideoSource(
        url: uri.toString(),
        platform: 'direct',
        extension: _extensionOf(uri),
      );
    }

    final host = uri.host.toLowerCase();
    final isYouTube = host == 'youtube.com' ||
        host.endsWith('.youtube.com') ||
        host == 'youtu.be';
    if (isYouTube) {
      return _resolveYouTube(uri);
    }

    final isTikTok = host == 'tiktok.com' || host.endsWith('.tiktok.com');
    final isInstagram =
        host == 'instagram.com' || host.endsWith('.instagram.com');
    if (!isTikTok && !isInstagram) {
      throw const SocialVideoDownloadException('unsupported');
    }

    final http = client ?? _client;
    try {
      final response = await http.get<dynamic>(
        uri.toString(),
        options: Options(responseType: ResponseType.plain),
      );
      if (response.statusCode != 200 || response.data is! String) {
        throw const SocialVideoDownloadException('source_unavailable');
      }

      final html = response.data as String;
      final candidates = isTikTok
          ? _extractTikTokCandidates(html)
          : _extractInstagramCandidates(html);
      if (candidates.isEmpty) {
        throw const SocialVideoDownloadException('source_unavailable');
      }

      candidates.sort((a, b) => b.score.compareTo(a.score));
      final selected = candidates.first;
      return SocialVideoSource(
        url: selected.url,
        platform: isTikTok ? 'tiktok' : 'instagram',
        extension: _extensionOf(Uri.parse(selected.url)),
        requestHeaders: _mediaRequestHeaders(
          pageUrl: response.realUri.toString(),
          response: response,
        ),
      );
    } on SocialVideoDownloadException {
      rethrow;
    } on DioException {
      throw const SocialVideoDownloadException('network');
    } catch (_) {
      throw const SocialVideoDownloadException('source_unavailable');
    }
  }

  static List<_Candidate> _extractTikTokCandidates(String html) {
    final document = html_parser.parse(html);
    final candidates = <_Candidate>[];

    for (final id in const [
      '__UNIVERSAL_DATA_FOR_REHYDRATION__',
      'SIGI_STATE',
      'api-data',
    ]) {
      final raw = document.getElementById(id)?.text.trim();
      if (raw == null || raw.isEmpty) continue;
      try {
        _collectCandidates(jsonDecode(raw), candidates);
      } catch (_) {
        // TikTok can serve a different state shape per region/user-agent.
      }
    }

    return _deduplicate(candidates);
  }

  static Map<String, String> _mediaRequestHeaders({
    required String pageUrl,
    required Response<dynamic> response,
  }) {
    final headers = <String, String>{
      'Referer': pageUrl,
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/122.0 Mobile Safari/537.36',
      'Accept': '*/*',
      'Accept-Encoding': 'identity',
    };
    final cookies = response.headers.map['set-cookie']
        ?.map((value) => value.split(';').first.trim())
        .where((value) => value.contains('='))
        .toSet()
        .join('; ');
    if (cookies != null && cookies.isNotEmpty) headers['Cookie'] = cookies;
    return headers;
  }

  static List<_Candidate> _extractInstagramCandidates(String html) {
    final document = html_parser.parse(html);
    final candidates = <_Candidate>[];

    for (final property in const [
      'og:video:secure_url',
      'og:video',
      'twitter:player:stream',
    ]) {
      final content = document
          .querySelector('meta[property="$property"], meta[name="$property"]')
          ?.attributes['content'];
      _addCandidate(candidates, content, score: 1000000);
    }

    for (final script in document.querySelectorAll('script')) {
      final raw = script.text.trim();
      if (raw.isEmpty ||
          (!raw.contains('video_url') && !raw.contains('contentUrl'))) {
        continue;
      }
      try {
        _collectCandidates(jsonDecode(raw), candidates);
      } catch (_) {
        for (final match in RegExp(
          r'"(?:video_url|contentUrl)"\s*:\s*"([^"]+)"',
        ).allMatches(raw)) {
          _addCandidate(candidates, match.group(1), score: 500000);
        }
      }
    }

    return _deduplicate(candidates);
  }

  static void _collectCandidates(
    dynamic value,
    List<_Candidate> output, {
    int inheritedScore = 0,
    String parentKey = '',
  }) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final width = _numberAt(map, 'width');
      final height = _numberAt(map, 'height');
      final bitrate = _numberAt(map, 'bitrate');
      final score = inheritedScore + (width * height) + bitrate;

      for (final entry in map.entries) {
        final key = entry.key.toLowerCase();
        final child = entry.value;
        final isNestedUrlList = key == 'url_list' || key == 'urllist';
        final isPlayableUrlList =
            isNestedUrlList &&
            (parentKey == 'playaddr' || parentKey == 'play_addr');
        if (_isMediaKey(key) && (!isNestedUrlList || isPlayableUrlList)) {
          if (child is String) _addCandidate(output, child, score: score);
          if (child is List) {
            for (final item in child) {
              if (item is String) _addCandidate(output, item, score: score);
            }
          }
        }
        _collectCandidates(
          child,
          output,
          inheritedScore: score,
          parentKey: key,
        );
      }
      return;
    }

    if (value is List) {
      for (var index = 0; index < value.length; index++) {
        final item = value[index];
        if (item is String &&
            _isMediaKey(parentKey) &&
            parentKey != 'url_list' &&
            parentKey != 'urllist') {
          _addCandidate(output, item, score: inheritedScore - index);
        } else {
          _collectCandidates(
            item,
            output,
            inheritedScore: inheritedScore,
            parentKey: parentKey,
          );
        }
      }
    }
  }

  static bool _isMediaKey(String key) => const {
    'playaddr',
    'play_addr',
    'playbackurl',
    'playback_url',
    'videourl',
    'video_url',
    'contenturl',
    'url_list',
    'urllist',
  }.contains(key);

  static void _addCandidate(
    List<_Candidate> output,
    String? raw, {
    required int score,
  }) {
    if (raw == null || raw.isEmpty) return;
    final decoded = raw
        .replaceAll(r'\u002F', '/')
        .replaceAll(r'\/', '/')
        .replaceAll('&amp;', '&');
    final uri = Uri.tryParse(decoded);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    if (_isPrivateHost(uri.host)) return;
    output.add(_Candidate(uri.toString(), score));
  }

  static List<_Candidate> _deduplicate(List<_Candidate> input) {
    final byUrl = <String, _Candidate>{};
    for (final candidate in input) {
      final current = byUrl[candidate.url];
      if (current == null || candidate.score > current.score) {
        byUrl[candidate.url] = candidate;
      }
    }
    return byUrl.values.toList();
  }

  static bool _isPrivateHost(String host) {
    final value = host.toLowerCase();
    if (value == 'localhost' || value.endsWith('.local')) return true;
    final ip = RegExp(
      r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
    ).firstMatch(value);
    if (ip == null) return false;
    final first = int.tryParse(ip.group(1)!) ?? 0;
    final second = int.tryParse(ip.group(2)!) ?? 0;
    return first == 10 ||
        first == 127 ||
        first == 0 ||
        (first == 169 && second == 254) ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _numberAt(Map<String, dynamic> map, String wantedKey) {
    for (final entry in map.entries) {
      if (entry.key.toLowerCase() == wantedKey) return _asInt(entry.value);
    }
    return 0;
  }

  static bool _isDirectVideo(Uri uri) {
    final path = uri.path.toLowerCase();
    return const ['.mp4', '.mov', '.m4v', '.webm'].any(path.endsWith);
  }

  static String _extensionOf(Uri uri) {
    final segment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    final dot = segment.lastIndexOf('.');
    if (dot == -1) return 'mp4';
    final extension = segment.substring(dot + 1).toLowerCase();
    return const {'mp4', 'mov', 'm4v', 'webm'}.contains(extension)
        ? extension
        : 'mp4';
  }

  static String? _extractYouTubeVideoId(Uri uri) {
    final pathSegments = uri.pathSegments;
    final shortsIndex = pathSegments.indexOf('shorts');
    if (shortsIndex != -1 && shortsIndex + 1 < pathSegments.length) {
      return pathSegments[shortsIndex + 1];
    }

    final host = uri.host.toLowerCase();
    if (host == 'youtu.be' && pathSegments.isNotEmpty) {
      return pathSegments.first;
    }

    if (uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v'];
    }

    try {
      return VideoId.parseVideoId(uri.toString());
    } catch (_) {
      return null;
    }
  }

  static Future<SocialVideoSource> _resolveYouTube(Uri uri) async {
    final videoId = _extractYouTubeVideoId(uri);
    if (videoId == null || videoId.isEmpty) {
      throw const SocialVideoDownloadException('invalid_url');
    }

    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final muxedStreams = manifest.muxed;
      if (muxedStreams.isEmpty) {
        throw const SocialVideoDownloadException('source_unavailable');
      }

      final streamInfo = muxedStreams.withHighestBitrate();
      return SocialVideoSource(
        url: streamInfo.url.toString(),
        platform: 'youtube',
        extension: streamInfo.container.name.isNotEmpty
            ? streamInfo.container.name
            : 'mp4',
      );
    } on VideoUnplayableException {
      throw const SocialVideoDownloadException('source_unavailable');
    } catch (e) {
      if (e is SocialVideoDownloadException) rethrow;
      throw const SocialVideoDownloadException('source_unavailable');
    } finally {
      yt.close();
    }
  }
}

class _Candidate {
  const _Candidate(this.url, this.score);

  final String url;
  final int score;
}
