import 'dart:convert';

import 'package:keep_link/core/data/models/db_model.dart';
import 'package:keep_link/features/link/application/model/meta_data_model.dart';

class LinkModel implements DbModel {
  @override
  final String id;
  final String? name;
  final String? image;
  final MetaDataModel? metaDataModel;
  final String? categoryId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  LinkModel({
    required this.id,
    this.name,
    this.image,
    this.metaDataModel,
    this.categoryId,
    this.createdAt,
    this.updatedAt,
  });

  factory LinkModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return LinkModel(
      id: id ?? json['id'],
      name: json['name'],
      image: json['image'],
      metaDataModel: json['metaData'] != null
          ? MetaDataModel.fromMap(jsonDecode(json['metaData']))
          : null,
      categoryId: json['categoryId'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "image": image,
      "metaData": metaDataModel != null
          ? jsonEncode(metaDataModel!.toMap())
          : null,
      "categoryId": categoryId,
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
    };
  }

  LinkModel copyWith({
    String? id,
    String? name,
    String? image,
    MetaDataModel? metaDataModel,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LinkModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      metaDataModel: metaDataModel ?? this.metaDataModel,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Ưu tiên đường dẫn thumbnail local bền vững nếu có, ngược lại dùng URL metadata
  String get displayImage {
    if (image != null && image!.trim().isNotEmpty) {
      return image!.trim();
    }
    return metaDataModel?.imageUrl.trim() ?? '';
  }

  @override
  String get tableName => "links";

  @override
  Map<String, String> get columns => {
    "id": "TEXT PRIMARY KEY",
    "name": "TEXT",
    "image": "TEXT",
    "metaData": "TEXT",
    "categoryId": "TEXT",
    "createdAt": "TEXT",
    "updatedAt": "TEXT",
  };

  @override
  List<String> get foreignKeys => [
    'FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE SET NULL',
  ];
}
