# HƯỚNG DẪN TRIỂN KHAI PUSH NOTIFICATION (CÁCH 2 - HOÀN TOÀN MIỄN PHÍ)

> **Mục tiêu**: Nhận thông báo đẩy (Push Notification) ngay cả khi **tắt hoàn toàn ứng dụng (killed app)** hoặc **khoá màn hình**, hoàn toàn **100% miễn phí** mà không cần nâng cấp Firebase Blaze hay nhập thẻ tín dụng.
>
> **Cơ chế**: App KeepLink -> Cloudflare Worker (Miễn phí 100.000 lượt/ngày) -> Google FCM HTTP v1 -> Điện thoại nhận thông báo.

---

## BƯỚC 1: LẤY SERVICE ACCOUNT TỪ FIREBASE CONSOLE

1. Truy cập [Firebase Console](https://console.firebase.google.com/) và chọn dự án **`linkcapture-13a10`**.
2. Bấm vào biểu tượng **Bánh răng ⚙️ (Project settings / Cài đặt dự án)** ở góc trên bên trái.
3. Chọn tab **Service accounts** (Tài khoản dịch vụ).
4. Bấm nút **Generate new private key** (Tạo khóa riêng tư mới) -> Xác nhận tạo khóa.
5. Một file `.json` sẽ được tải về máy tính của bạn (ví dụ: `linkcapture-13a10-firebase-adminsdk-xxxxx.json`).
6. Mở file `.json` đó lên bằng Notepad hoặc VS Code. Bạn sẽ thấy 2 trường cần lấy:
   - `"client_email"`: có dạng `firebase-adminsdk-xxxxx@linkcapture-13a10.iam.gserviceaccount.com`
   - `"private_key"`: chuỗi khóa dài bắt đầu bằng `-----BEGIN PRIVATE KEY-----\n...`

---

## BƯỚC 2: TẠO VÀ DEPLOY CLOUDFLARE WORKER

1. Truy cập [Cloudflare Dashboard](https://dash.cloudflare.com/) (đăng ký tài khoản miễn phí nếu chưa có, Cloudflare **không yêu cầu thẻ tín dụng**).
2. Ở thanh menu bên trái, chọn **Workers & Pages** (hoặc **Compute (Workers & Pages)**).
3. Bấm **Create application** -> Chọn tab **Workers** -> Bấm **Create Worker**.
4. Đặt tên cho Worker (ví dụ: `keeplink-push`) -> Bấm **Deploy**.
5. Sau khi tạo xong, bấm vào nút **Edit code** (Chỉnh sửa mã).
6. Mở file `cloudflare_worker/worker.js` trong thư mục dự án KeepLink:
   - Điền `client_email` bạn vừa lấy ở Bước 1 vào `client_email: "..."`.
   - Điền `private_key` bạn vừa lấy ở Bước 1 vào `private_key: \`...\``.
7. Copy toàn bộ nội dung file `worker.js` và dán đè vào trình soạn thảo code trên Cloudflare (thay thế mã code mặc định).
8. Bấm nút **Deploy** (hoặc **Save and Deploy**) ở góc trên bên phải.
9. Sau khi deploy thành công, bạn quay lại trang chi tiết Worker và copy đường dẫn URL của Worker (ví dụ: `https://keeplink-push.ten-subdomain-cua-ban.workers.dev`).

---

## BƯỚC 3: CẬP NHẬT URL VÀO APP FLUTTER

Mở file `lib/core/config/constants/push_notification_config.dart` trong mã nguồn Flutter:

```dart
class PushNotificationConfig {
  /// Dán link Worker của bạn vào đây kèm theo đuôi /send-notification:
  static const String workerUrl = 'https://keeplink-push.ten-subdomain-cua-ban.workers.dev/send-notification';

  /// Giữ nguyên secret key để bảo mật
  static const String apiSecret = 'keeplink_fcm_secret_2026';
}
```

Lưu file lại.

---

## BƯỚC 4: TEST THỰC TẾ TRÊN 2 THIẾT BỊ

1. Cài đặt app lên **Thiết bị 2** (người nhận):
   - Mở app đăng nhập 1 lần. App sẽ tự động xin quyền thông báo và lưu `fcmToken` của Thiết bị 2 lên Firebase Realtime Database.
   - Sau đó **vuốt tắt hoàn toàn app** (kill app từ Recent Apps) hoặc **khoá màn hình**.
2. Trên **Thiết bị 1** (người gửi):
   - Mở app -> Chọn chia sẻ một liên kết hoặc thư mục đến tài khoản của Thiết bị 2.
3. **Kết quả**:
   - Thiết bị 2 lập tức sáng màn hình và nhận thông báo đẩy từ hệ điều hành Android/iOS dù app đang đóng hoàn toàn.
   - Khi bấm vào thông báo, app sẽ tự động mở lên và chuyển thẳng vào trang **"Trao đổi link"**!
