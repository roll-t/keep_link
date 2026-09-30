class PushNotificationConfig {
  /// URL của Cloudflare Worker endpoint xử lý gửi thông báo FCM.
  /// Thay thế URL này sau khi deploy Worker trên Cloudflare.
  static const String workerUrl = "https://keeplink-push.phuoctruong727.workers.dev/";

  /// Mã secret dùng để xác thực an toàn giữa App KeepLink và Cloudflare Worker (tùy chọn)
  static const String apiSecret = 'keeplink_fcm_secret_2026';
}
