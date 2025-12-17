import 'package:keep_link/core/config/app_enum.dart';

class ItemModel {
  String? id;
  String? name;
  VisibilityStatus visibility;

  ItemModel({this.id, this.name, this.visibility = VisibilityStatus.public});

  // From JSON
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
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
