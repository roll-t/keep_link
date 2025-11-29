class ItemModel {
  String? id;
  String? name;

  ItemModel({this.id, this.name});

  // From JSON
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(id: json['id'] as String?, name: json['name'] as String?);
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
