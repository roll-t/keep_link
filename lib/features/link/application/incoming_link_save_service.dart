import 'dart:async';

import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/repositories/link_repository.dart';
import 'package:keep_link/core/services/backend/link_metadata_service.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/application/model/meta_data_model.dart';

enum IncomingLinkSaveStatus { saved, duplicate }

class IncomingLinkSaveResult {
  const IncomingLinkSaveResult({required this.status, required this.link});

  final IncomingLinkSaveStatus status;
  final LinkModel link;
}

class IncomingLinkException implements Exception {
  const IncomingLinkException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Parses and saves links received from Android's share sheet.
class IncomingLinkSaveService {
  IncomingLinkSaveService._();

  static final RegExp _urlPattern = RegExp(
    r'https?://[^\s<>"“”]+',
    caseSensitive: false,
  );

  static String? extractUrl(String sharedText) {
    final match = _urlPattern.firstMatch(sharedText.trim());
    if (match == null) return null;
    var value = match.group(0) ?? '';
    const trailingCharacters = '.,;:!?)]}';
    while (value.isNotEmpty &&
        trailingCharacters.contains(value[value.length - 1])) {
      value = value.substring(0, value.length - 1);
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return value;
  }

  static String normalizeUrl(String url) {
    final uri = Uri.parse(url.trim());
    var path = uri.path;
    if (path == '/') path = '';
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return uri
        .replace(
          scheme: uri.scheme.toLowerCase(),
          host: uri.host.toLowerCase(),
          path: path,
        )
        .removeFragment()
        .toString();
  }

  static String fallbackTitle(String sharedText, String url) {
    final surroundingText = sharedText
        .replaceFirst(url, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (surroundingText.isNotEmpty) {
      return surroundingText.length <= 120
          ? surroundingText
          : '${surroundingText.substring(0, 117)}...';
    }
    return Uri.parse(url).host.replaceFirst(RegExp(r'^www\.'), '');
  }

  static Future<IncomingLinkSaveResult> save(String sharedText) async {
    final extractedUrl = extractUrl(sharedText);
    if (extractedUrl == null) {
      throw const IncomingLinkException('Không tìm thấy đường dẫn hợp lệ');
    }

    final normalizedUrl = normalizeUrl(extractedUrl);
    await LinkRepository.ensureLoaded();

    for (final existing in AppCache.links) {
      final existingUrl = existing.metaDataModel?.url.trim();
      if (existingUrl == null || existingUrl.isEmpty) continue;
      try {
        if (normalizeUrl(existingUrl) == normalizedUrl) {
          return IncomingLinkSaveResult(
            status: IncomingLinkSaveStatus.duplicate,
            link: existing,
          );
        }
      } catch (_) {}
    }

    final fallback = fallbackTitle(sharedText, extractedUrl);
    final metadata = await LinkMetadataService.fetch(extractedUrl).timeout(
      const Duration(seconds: 7),
      onTimeout: () => LinkMetadataService.empty(extractedUrl),
    );
    final effectiveMetadata = _withFallback(metadata, extractedUrl, fallback);
    final now = DateTime.now();
    final link = LinkModel(
      id: now.microsecondsSinceEpoch.toString(),
      name: effectiveMetadata.title,
      metaDataModel: effectiveMetadata,
      categoryId: null,
      createdAt: now,
      updatedAt: now,
    );

    await LinkRepository.insert(link, syncImmediately: false);
    return IncomingLinkSaveResult(
      status: IncomingLinkSaveStatus.saved,
      link: link,
    );
  }

  static MetaDataModel _withFallback(
    MetaDataModel metadata,
    String url,
    String fallback,
  ) {
    return metadata.copyWith(
      url: url,
      title: metadata.title.trim().isEmpty ? fallback : metadata.title.trim(),
    );
  }
}
