class AuthorModel {
  final String id;
  final String username;
  final String name;
  final String avatar;
  final num? followerCount;
  final num? followingCount;
  final num? videoCount;
  final num? heartCount;
  final num? diggCount;

  AuthorModel({
    required this.id,
    required this.username,
    required this.name,
    required this.avatar,
    this.followerCount,
    this.followingCount,
    this.videoCount,
    this.heartCount,
    this.diggCount,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      followerCount: json['followerCount'],
      followingCount: json['followingCount'],
      videoCount: json['videoCount'],
      heartCount: json['heartCount'],
      diggCount: json['diggCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'avatar': avatar,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'videoCount': videoCount,
      'heartCount': heartCount,
      'diggCount': diggCount,
    };
  }

  AuthorModel copyWith({
    String? id,
    String? username,
    String? name,
    String? avatar,
    num? followerCount,
    num? followingCount,
    num? videoCount,
    num? heartCount,
    num? diggCount,
  }) {
    return AuthorModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      videoCount: videoCount ?? this.videoCount,
      heartCount: heartCount ?? this.heartCount,
      diggCount: diggCount ?? this.diggCount,
    );
  }

  Map<String, dynamic> toMap() => toJson();
}
