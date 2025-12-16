import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/model/db_model.dart';

class CategoryModel implements DbModel {
  @override
  String? id;
  String? name;
  String? description;
  String? iconUrl;

  /// 🔐 Quyền hiển thị / bảo mật danh mục
  CategoryVisibility visibility;

  /// Thời gian tạo và cập nhật
  DateTime? createdAt;
  DateTime? updatedAt;

  CategoryModel({
    this.id,
    this.name,
    this.description,
    this.iconUrl,
    this.visibility = CategoryVisibility.private, // ✅ default an toàn
    this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  @override
  String get tableName => 'categories';

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon_url': iconUrl,
    'visibility': visibility.name, // ✅ lưu string
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  /// Helper parse từ DB
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['icon_url'],
      visibility: CategoryVisibility.values.firstWhere(
        (e) => e.name == json['visibility'],
        orElse: () => CategoryVisibility.private,
      ),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  @override
  Map<String, String> get columns => {
    'id': 'TEXT PRIMARY KEY',
    'name': 'TEXT NOT NULL',
    'description': 'TEXT',
    'icon_url': 'TEXT',
    'visibility': 'TEXT NOT NULL DEFAULT "private"', // ✅ thêm cột
    'created_at': 'TEXT',
    'updated_at': 'TEXT',
  };

  @override
  List<String> get foreignKeys => [];
}
