import 'package:keep_link/features/link/application/model/link_model.dart';

/// Represents an individual link that a friend has shared with the current user.
class SharedIndividualLinkModel {
  final String ownerUid;
  final String ownerDisplayName;
  final String? ownerPhotoUrl;
  final String linkId;
  final LinkModel link;
  final DateTime? sharedAt;

  const SharedIndividualLinkModel({
    required this.ownerUid,
    required this.ownerDisplayName,
    this.ownerPhotoUrl,
    required this.linkId,
    required this.link,
    this.sharedAt,
  });

  factory SharedIndividualLinkModel.fromJson({
    required String ownerUid,
    required String ownerDisplayName,
    String? ownerPhotoUrl,
    required String linkId,
    required Map<String, dynamic> linkJson,
    DateTime? sharedAt,
  }) {
    return SharedIndividualLinkModel(
      ownerUid: ownerUid,
      ownerDisplayName: ownerDisplayName,
      ownerPhotoUrl: ownerPhotoUrl,
      linkId: linkId,
      link: LinkModel.fromJson(linkJson, id: linkId),
      sharedAt: sharedAt,
    );
  }
}
