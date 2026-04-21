import 'package:keep_link/core/model/db_model.dart';

class FriendModel extends DbModel {
  FriendModel({
    this.id,
    this.friendUserId = '',
    this.displayName = '',
    this.email,
    this.photoUrl,
    this.sourceLink,
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
  });

  @override
  final String? id;
  final String friendUserId;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final String? sourceLink;
  final bool isFavorite;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id']?.toString(),
      friendUserId: (json['friend_user_id'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      email: json['email']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      sourceLink: json['source_link']?.toString(),
      isFavorite: (json['is_favorite'] ?? 0) == 1,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  FriendModel copyWith({
    String? id,
    String? friendUserId,
    String? displayName,
    String? email,
    String? photoUrl,
    String? sourceLink,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FriendModel(
      id: id ?? this.id,
      friendUserId: friendUserId ?? this.friendUserId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      sourceLink: sourceLink ?? this.sourceLink,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String get tableName => 'friends';

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'friend_user_id': friendUserId,
      'display_name': displayName,
      'email': email,
      'photo_url': photoUrl,
      'source_link': sourceLink,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  Map<String, String> get columns => {
    'id': 'TEXT PRIMARY KEY',
    'friend_user_id': 'TEXT NOT NULL',
    'display_name': 'TEXT NOT NULL',
    'email': 'TEXT',
    'photo_url': 'TEXT',
    'source_link': 'TEXT',
    'is_favorite': 'INTEGER NOT NULL DEFAULT 0',
    'created_at': 'TEXT',
    'updated_at': 'TEXT',
  };

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString();
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
