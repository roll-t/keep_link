import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication auth = LocalAuthentication();

  /// Kiểm tra thiết bị có hỗ trợ sinh trắc học hay không
  static Future<bool> isSupported() async {
    return await auth.isDeviceSupported();
  }

  /// Kiểm tra có đăng ký vân tay chưa
  static Future<bool> canCheck() async {
    return await auth.canCheckBiometrics;
  }

  /// Xác thực vân tay
  static Future<bool> authenticate() async {
    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: "Xác thực bằng vân tay để tiếp tục",
        biometricOnly: true,
        sensitiveTransaction: true,
      );

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }
}
