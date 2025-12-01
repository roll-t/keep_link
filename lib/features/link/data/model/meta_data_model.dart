class MetaDataModel {
  String url;
  String title;
  String description;
  String imageUrl;
  String favicon;
  String appleIcon;

  MetaDataModel({
    required this.url,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.favicon,
    required this.appleIcon,
  });

  /// Tạo từ Map
  factory MetaDataModel.fromMap(Map<String, dynamic> map) {
    return MetaDataModel(
      url: map['URL'] ?? '',
      title: map['TITLE'] ?? '',
      description: map['DESCRIPTION'] ?? '',
      imageUrl: map['IMAGE_URL'] ?? '',
      favicon: map['FAVICON'] ?? '',
      appleIcon: map['APPLE_ICON'] ?? '',
    );
  }

  /// Chuyển về Map (nếu cần)
  Map<String, dynamic> toMap() {
    return {
      'URL': url,
      'TITLE': title,
      'DESCRIPTION': description,
      'IMAGE_URL': imageUrl,
      'FAVICON': favicon,
      'APPLE_ICON': appleIcon,
    };
  }

  MetaDataModel copyWith({
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    String? favicon,
    String? appleIcon,
  }) {
    return MetaDataModel(
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      favicon: favicon ?? this.favicon,
      appleIcon: appleIcon ?? this.appleIcon,
    );
  }

  @override
  String toString() {
    return 'MetaDataModel(url: $url, title: $title, description: $description, imageUrl: $imageUrl, favicon: $favicon, appleIcon: $appleIcon)';
  }
}
