/// Represents a category that a friend has shared with the current user.
class SharedCategoryModel {
  final String ownerUid;
  final String ownerDisplayName;
  final String? ownerPhotoUrl;
  final String categoryId;
  final String categoryName;
  final String? categoryDescription;
  final int linkCount;
  final DateTime? sharedAt;

  const SharedCategoryModel({
    required this.ownerUid,
    required this.ownerDisplayName,
    this.ownerPhotoUrl,
    required this.categoryId,
    required this.categoryName,
    this.categoryDescription,
    this.linkCount = 0,
    this.sharedAt,
  });

  factory SharedCategoryModel.fromJson({
    required String ownerUid,
    required String ownerDisplayName,
    String? ownerPhotoUrl,
    required String categoryId,
    required Map<String, dynamic> categoryJson,
    int linkCount = 0,
    DateTime? sharedAt,
  }) {
    return SharedCategoryModel(
      ownerUid: ownerUid,
      ownerDisplayName: ownerDisplayName,
      ownerPhotoUrl: ownerPhotoUrl,
      categoryId: categoryId,
      categoryName: (categoryJson['name'] ?? '').toString(),
      categoryDescription: categoryJson['description']?.toString(),
      linkCount: linkCount,
      sharedAt: sharedAt,
    );
  }

  SharedCategoryModel copyWithLinkCount(int linkCount) {
    return SharedCategoryModel(
      ownerUid: ownerUid,
      ownerDisplayName: ownerDisplayName,
      ownerPhotoUrl: ownerPhotoUrl,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryDescription: categoryDescription,
      linkCount: linkCount,
      sharedAt: sharedAt,
    );
  }
}
