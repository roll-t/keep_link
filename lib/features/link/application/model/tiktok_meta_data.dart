import 'package:keep_link/features/link/application/model/author_model.dart';
import 'package:keep_link/features/link/application/model/meta_data_model.dart';

class TiktokMetaData {
  final String id;
  final String description;
  final String thumbnail;
  final List<String> downloadUrls;
  final String audioUrl;
  final String createTime;
  final int duration;
  final int height;
  final int width;
  final String defaultResolution;
  final AuthorModel author;

  TiktokMetaData({
    required this.id,
    required this.description,
    required this.thumbnail,
    required this.downloadUrls,
    required this.audioUrl,
    required this.createTime,
    required this.duration,
    required this.height,
    required this.width,
    required this.defaultResolution,
    required this.author,
  });

  /// ✅ JSON → Model
  factory TiktokMetaData.fromJson(Map<String, dynamic> json) {
    return TiktokMetaData(
      id: json['id']?.toString() ?? '',
      description: json['description'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      downloadUrls: (json['downloadUrls'] is List)
          ? List<String>.from(json['downloadUrls'])
          : <String>[],
      audioUrl: json['audioUrl'] ?? '',
      createTime: json['createTime']?.toString() ?? '',
      duration: _parseInt(json['duration']),
      height: _parseInt(json['height']),
      width: _parseInt(json['width']),
      defaultResolution: json['defaultResolution'] ?? '',
      author: AuthorModel.fromJson(json['author'] ?? {}),
    );
  }

  /// ✅ Model → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'thumbnail': thumbnail,
      'downloadUrls': downloadUrls,
      'audioUrl': audioUrl,
      'createTime': createTime,
      'duration': duration,
      'height': height,
      'width': width,
      'defaultResolution': defaultResolution,
      'author': author.toJson(),
    };
  }

  /// ✅ Chuyển sang MetaDataModel (dùng hiển thị UI chat preview)
  MetaDataModel toMetaData() {
    final caption = description.isNotEmpty ? '“$description”' : '';
    return MetaDataModel(
      url: "",
      title: author.name.isNotEmpty ? author.name : '${author.username} $caption'.trim(),
      description: description,
      imageUrl: thumbnail,
      favicon: '',
      appleIcon: '',
    );
  }

  /// ✅ Safe parse int
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
