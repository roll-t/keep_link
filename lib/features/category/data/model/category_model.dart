import 'package:keep_link/core/model/db_model.dart';

class CategoryModel implements DbModel {
  @override
  String? id;
  String? name;
  String? description;
  String? iconUrl;

  /// Thời gian tạo và cập nhật
  DateTime? createdAt;
  DateTime? updatedAt;

  CategoryModel({
    this.id,
    this.name,
    this.description,
    this.iconUrl,
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
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  @override
  Map<String, String> get columns => {
    'id': 'TEXT PRIMARY KEY',
    'name': 'TEXT NOT NULL',
    'description': 'TEXT',
    'icon_url': 'TEXT',
    'createdAt': 'TEXT',
    'updated_at': 'TEXT',
  };

  @override
  List<String> get foreignKeys => [];
}
