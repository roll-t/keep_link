import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/cache/sql_lite.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

/// Quản lý lưu trữ thumbnail vĩnh viễn trong thư mục Documents của ứng dụng.
///
/// Các file trong thư mục này KHÔNG BAO GIỜ bị hệ điều hành xóa (khác với cache).
/// Thumbnail sẽ được lưu giữ vĩnh viễn cho đến khi người dùng xóa link.
class LinkThumbnailService {
  LinkThumbnailService._();

  /// Danh sách các linkId đã tải thumbnail thất bại trong phiên làm việc hiện tại
  /// (tránh gửi request và spam log nhiều lần cho các CDN URL đã hết hạn / bị chặn 403)
  static final Set<String> _failedLinkIds = {};

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        'Accept':
            'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
        'Accept-Language': 'vi,en-US;q=0.9,en;q=0.8',
        'Sec-Fetch-Dest': 'image',
        'Sec-Fetch-Mode': 'no-cors',
        'Sec-Fetch-Site': 'cross-site',
      },
    ),
  );

  static Directory? _thumbnailDir;

  /// Thư mục lưu trữ thumbnail vĩnh viễn (app documents/thumbnails)
  static Future<Directory?> getThumbnailDirectory() async {
    if (_thumbnailDir != null) return _thumbnailDir;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${docsDir.path}${Platform.pathSeparator}thumbnails');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _thumbnailDir = dir;
      return dir;
    } catch (e) {
      log('Lỗi lấy thư mục thumbnails: $e');
      return null;
    }
  }

  /// Đường dẫn file local cho linkId
  static Future<String?> getThumbnailPathForId(String linkId) async {
    final dir = await getThumbnailDirectory();
    if (dir == null) return null;
    return '${dir.path}${Platform.pathSeparator}$linkId.jpg';
  }

  /// Trả về đường dẫn nếu file thumbnail local đã tồn tại và hợp lệ
  static Future<String?> getExistingThumbnailPath(String linkId) async {
    if (linkId.isEmpty) return null;
    try {
      final path = await getThumbnailPathForId(linkId);
      if (path == null) return null;
      final file = File(path);
      if (await file.exists() && await file.length() > 0) {
        return path;
      }
    } catch (_) {}
    return null;
  }

  /// Tải và lưu ảnh thumbnail vào thư mục vĩnh viễn
  static Future<String?> saveThumbnail({
    required String linkId,
    required String? remoteUrl,
  }) async {
    if (linkId.isEmpty || remoteUrl == null || remoteUrl.trim().isEmpty) {
      return null;
    }
    if (_failedLinkIds.contains(linkId)) {
      return null;
    }
    final url = remoteUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return null;
    }

    File? tempFile;
    try {
      final filePath = await getThumbnailPathForId(linkId);
      if (filePath == null) return null;
      final file = File(filePath);

      // Nếu file đã có sẵn và hợp lệ thì không cần tải lại
      if (await file.exists() && await file.length() > 0) {
        return filePath;
      }

      final tempPath = '$filePath.tmp';
      tempFile = File(tempPath);

      final uri = Uri.tryParse(url);
      final reqHeaders = <String, String>{};
      if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
        reqHeaders['Referer'] = '${uri.scheme}://${uri.host}/';
      }

      final response = await _dio.download(
        url,
        tempPath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) => status != null && status < 500,
          headers: reqHeaders.isNotEmpty ? reqHeaders : null,
        ),
      );

      if (response.statusCode == 200 &&
          await tempFile.exists() &&
          await tempFile.length() > 0) {
        if (await file.exists()) await file.delete();
        await tempFile.rename(filePath);
        _failedLinkIds.remove(linkId);
        return filePath;
      } else {
        _failedLinkIds.add(linkId);
        log('Không thể tải thumbnail link $linkId: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _failedLinkIds.add(linkId);
      if (e is DioException) {
        log('Lỗi mạng tải thumbnail link $linkId: ${e.response?.statusCode ?? e.type}');
      } else {
        log('Lỗi lưu thumbnail cho link $linkId: $e');
      }
      return null;
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  /// Tải thumbnail và tự động cập nhật trường `image` của link trong SQLite & AppCache
  static Future<void> saveAndAttachThumbnail(LinkModel link) async {
    final remoteUrl = link.metaDataModel?.imageUrl;
    if (remoteUrl == null || remoteUrl.trim().isEmpty) return;

    _failedLinkIds.remove(link.id);
    final localPath = await saveThumbnail(
      linkId: link.id,
      remoteUrl: remoteUrl,
    );
    if (localPath != null) {
      final updated = link.copyWith(image: localPath);
      await DbHelper.update('links', link.id, {'image': localPath});
      AppCache.updateLink(updated);
    }
  }

  /// Xóa file thumbnail khi link bị xóa
  static Future<void> deleteThumbnail(String linkId) async {
    if (linkId.isEmpty) return;
    _failedLinkIds.remove(linkId);
    try {
      final path = await getThumbnailPathForId(linkId);
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      log('Lỗi xóa thumbnail cho link $linkId: $e');
    }
  }

  /// Xóa nhiều file thumbnail khi xóa batch
  static Future<void> deleteThumbnails(Iterable<String> linkIds) async {
    for (final id in linkIds) {
      await deleteThumbnail(id);
    }
  }

  /// Tự động quét và tải thumbnail local cho các link cũ chưa có file lưu bền vững
  static void backfillThumbnails(List<LinkModel> links) {
    unawaited(Future.microtask(() async {
      for (final link in links) {
        if (_failedLinkIds.contains(link.id)) continue;

        final remoteUrl = link.metaDataModel?.imageUrl;
        if (remoteUrl == null || remoteUrl.trim().isEmpty) continue;

        final existing = await getExistingThumbnailPath(link.id);
        if (existing == null) {
          final localPath = await saveThumbnail(
            linkId: link.id,
            remoteUrl: remoteUrl,
          );
          if (localPath != null) {
            final updated = link.copyWith(image: localPath);
            await DbHelper.update('links', link.id, {'image': localPath});
            AppCache.updateLink(updated);
          }
        } else if (link.image != existing) {
          final updated = link.copyWith(image: existing);
          await DbHelper.update('links', link.id, {'image': existing});
          AppCache.updateLink(updated);
        }
      }
    }));
  }

  /// Xóa danh sách cache lỗi nếu muốn thử tải lại thủ công
  static void clearFailedCache() => _failedLinkIds.clear();
}
