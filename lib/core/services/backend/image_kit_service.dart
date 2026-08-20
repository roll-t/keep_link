import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';

/// Wrapper gọi native ImageKit Android SDK qua MethodChannel.
/// Upload xử lý hoàn toàn qua imagekit-android SDK (JitPack 3.0.1).
/// JWT được sinh trực tiếp trên thiết bị — không cần backend server.
///
/// Config keys đặt tại:
///   android/app/src/main/kotlin/.../channel/ImageKitChannel.kt
class ImageKitService {
  ImageKitService._();

  static const _channel = MethodChannel('keep_link/imagekit');

  // URL endpoint dùng cho transform() — phải khớp với giá trị trong ImageKitChannel.kt
  static const String _urlEndpoint = 'https://ik.imagekit.io/lcr78qp6g';

  // ─── Upload ───────────────────────────────────────────────────────────────

  /// Upload file lên ImageKit qua native Android SDK.
  /// Trả về URL public của ảnh sau khi upload thành công, null nếu thất bại.
  static Future<String?> uploadFile({
    required File file,
    String folder = '/avatars',
    String? fileName,
  }) async {
    if (!Platform.isAndroid) {
      // iOS chưa hỗ trợ native SDK — fallback thông báo
      log('ImageKit native SDK chỉ hỗ trợ Android hiện tại');
      return null;
    }
    try {
      final name = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await _channel.invokeMethod<String>('uploadFile', {
        'filePath': file.path,
        'fileName': name,
        'folder': folder,
      });
      log('ImageKit upload success: $url');
      return url;
    } on PlatformException catch (e) {
      log('ImageKit upload error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      log('ImageKit upload error: $e');
      return null;
    }
  }

  // ─── Transform URL ────────────────────────────────────────────────────────

  /// Tạo URL transform từ URL gốc trên ImageKit CDN.
  /// Ví dụ: ImageKitService.transform(url, width: 200, height: 200)
  /// → https://ik.imagekit.io/id/tr:w-200,h-200,q-80,f-webp/folder/file.jpg
  static String transform(
    String url, {
    int? width,
    int? height,
    int quality = 80,
    String format = 'webp',
  }) {
    if (!url.contains(_urlEndpoint)) return url;

    final params = <String>[];
    if (width != null) params.add('w-$width');
    if (height != null) params.add('h-$height');
    params.add('q-$quality');
    params.add('f-$format');

    final uri = Uri.parse(url);
    final newPath = '/tr:${params.join(',')}${uri.path}';
    return uri.replace(path: newPath).toString();
  }
}
