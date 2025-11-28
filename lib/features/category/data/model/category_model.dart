import 'package:keep_link/core/model/db_model.dart';

class CategoryModel implements DbModel {
  @override
  String id;
  String name;
  String? description;
  String? iconUrl;

  CategoryModel({required this.id, required this.name, this.description, this.iconUrl});

  @override
  String get tableName => 'categories';

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'icon_url': iconUrl,
  };

  @override
  Map<String, String> get columns => {
    'id': 'TEXT PRIMARY KEY',
    'name': 'TEXT NOT NULL',
    'description': 'TEXT',
    'icon_url': 'TEXT',
  };
}
