abstract class DbModel {
  String get tableName; // tên bảng
  String get id; // khóa chính
  Map<String, dynamic> toMap(); // model -> map
  Map<String, String> get columns; // tên cột + kiểu SQL, dùng để tạo bảng
}
