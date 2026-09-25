import 'package:flutter/material.dart';
import 'package:keep_link/core/presentation/widgets/sheet/share_recipient_sheet.dart';

/// Recipient picker for sharing a category with Linkeep friends.
/// Uses the unified [ShareRecipientSheet] layout.
class ShareCategorySheet extends StatelessWidget {
  const ShareCategorySheet({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final String categoryId;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return ShareRecipientSheet.category(
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }
}
