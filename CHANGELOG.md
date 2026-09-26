# Changelog

All notable changes to Linkeep will be documented in this file.

## [1.0.6] - 2026-09-26

### Added
- **Bóng lưu nhanh (Floating Bubble)**: 
  - Thêm bóng nổi tiện ích trên màn hình hỗ trợ lưu nhanh URL từ trình duyệt web và video TikTok mà không cần chuyển qua lại giữa các ứng dụng.
  - Tích hợp quyền trợ năng (Accessibility Service) và Clipboard Capture để tự động nhận diện liên kết.
  - Tùy chọn bật/tắt và hướng dẫn cấp quyền trong mục Cài đặt (`settings_page.dart`).
- **Chia sẻ nhanh qua Android Share Sheet (Quick Share)**:
  - Tích hợp `ShareReceiverActivity` tiếp nhận liên kết trực tiếp từ menu chia sẻ hệ thống Android.
  - Giao diện pop-up Quick Share (`quick_share_page.dart`) trực quan, tự động cào ảnh preview và thông tin liên kết (`link_metadata_service.dart`).
- **Tính năng Bạn bè & Chia sẻ bộ sưu tập (Friend Connection)**:
  - Kết bạn thông qua mã QR cá nhân và trình quét mã QR (`my_qr_page.dart`, `qr_scanner_page.dart`).
  - Chia sẻ nhanh từng liên kết hoặc toàn bộ danh mục liên kết với bạn bè theo thời gian thực (`firebase_service.dart`).

### Improvements & Fixes
- Tối ưu hóa hiệu năng render danh sách liên kết và danh mục.
- Cải thiện độ mượt cho trình xem trước đa phương tiện (Hero Media).
- Tinh chỉnh giao diện Cài đặt và Bảo mật (Mã PIN & Sinh trắc học).
- Sửa các lỗi vặt và nâng cao tính ổn định của ứng dụng.

---

## [1.0.5] - 2026-09-25
- Cập nhật kiến trúc kết nối bạn bè và đồng bộ phiên đăng nhập đơn thiết bị.
- Nâng cấp giao diện người dùng và hệ thống chủ đề/màu sắc.
- Hỗ trợ đa ngôn ngữ và tối ưu hóa lưu trữ cục bộ.
