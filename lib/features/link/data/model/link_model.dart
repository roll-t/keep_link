import 'package:keep_link/core/model/db_model.dart';
import 'package:keep_link/features/link/data/model/meta_data_model.dart';

class LinkModel implements DbModel {
  @override
  final String id;
  final String? title;
  final String? image;
  final MetaDataModel? metaDataModel;
  final String? categoryId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  LinkModel({
    required this.id,
    this.title,
    this.image,
    this.metaDataModel,
    this.categoryId,
    this.createdAt,
    this.updatedAt,
  });

  /// -----------------------------
  /// JSON → LinkModel
  /// -----------------------------
  factory LinkModel.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return LinkModel(
      id: id ?? json['id'],
      title: json['name'] ?? '',
      image: json['image'] ?? '',
      metaDataModel: json['metaData'] != null
          ? MetaDataModel.fromMap(Map<String, dynamic>.from(json['metaData']))
          : null,
      categoryId: json['categoryId'],
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  /// -----------------------------
  /// LinkModel → JSON
  /// -----------------------------
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': title,
      'image': image,
      'metaData': metaDataModel?.toMap(),
      'categoryId': categoryId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// -----------------------------
  /// CopyWith
  /// -----------------------------
  LinkModel copyWith({
    String? id,
    String? title,
    String? image,
    MetaDataModel? metaDataModel,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LinkModel(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      metaDataModel: metaDataModel ?? this.metaDataModel,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ==========================================================
  /// SQLite IMPLEMENTATION
  /// ==========================================================

  @override
  String get tableName => "links";

  @override
  Map<String, String> get columns => {
    "id": "TEXT PRIMARY KEY",
    "title": "TEXT",
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
