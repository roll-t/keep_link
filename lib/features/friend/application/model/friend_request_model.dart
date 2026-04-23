class FriendRequestModel {
  const FriendRequestModel({
    required this.fromUserId,
    required this.displayName,
    this.email,
    this.photoUrl,
    this.sourceLink,
    this.createdAt,
    this.updatedAt,
    this.status = 'pending',
  });

  final String fromUserId;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final String? sourceLink;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String status;

  factory FriendRequestModel.fromJson(String fromUserId, Map<String, dynamic> json) {
    return FriendRequestModel(
      fromUserId: fromUserId,
      displayName: (json['displayName'] ?? json['display_name'] ?? '').toString(),
      email: json['email']?.toString(),
      photoUrl: (json['photoUrl'] ?? json['photo_url'] ?? json['avatarUrl'])?.toString(),
      sourceLink: json['sourceLink']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      status: (json['status'] ?? 'pending').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'sourceLink': sourceLink,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status,
    };
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString();
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
