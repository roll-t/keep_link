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
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "image": image,
      "metaData": metaDataModel != null ? jsonEncode(metaDataModel!.toMap()) : null,
      "categoryId": categoryId,
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
    };
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
