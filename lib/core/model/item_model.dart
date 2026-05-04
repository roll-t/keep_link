import 'package:keep_link/core/config/app_enum.dart';

class ItemModel {
  String? id;
  String? name;
  VisibilityStatus visibility;
  int? chilrenCount;
  bool isPinned;

  ItemModel({
    this.id,
    this.name,
    this.visibility = VisibilityStatus.public,
    this.chilrenCount,
    this.isPinned = false,
  });

  // From JSON
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      chilrenCount: json['children_count'] as int?,
      visibility: VisibilityStatus.values.firstWhere(
        (e) => e.name == json['visibility'],
        orElse: () => VisibilityStatus.public,
      ),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'visibility': visibility.name};
  }
}
