import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'FirebaseOptions chưa cấu hình cho web. Hãy chạy flutterfire configure để thêm web config.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'FirebaseOptions chưa cấu hình cho nền tảng này. Hãy chạy flutterfire configure.',
        );
      default:
        throw UnsupportedError('Nền tảng không được hỗ trợ.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD3ujaqfKmnGhg0K3VcEE1XK2hPVjZAKks',
    appId: '1:536130567578:android:f16fa9bf43154ce3364e23',
    messagingSenderId: '536130567578',
    projectId: 'linkcapture-13a10',
    storageBucket: 'linkcapture-13a10.firebasestorage.app',
  );
}
