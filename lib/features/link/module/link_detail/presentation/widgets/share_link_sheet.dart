import 'package:flutter/material.dart';
import 'package:keep_link/core/presentation/widgets/sheet/share_recipient_sheet.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

/// Bottom sheet that lets the user share/unshare an individual link with friends.
/// Uses the unified [ShareRecipientSheet] layout, identical to Home share format.
class ShareLinkSheet extends StatelessWidget {
  final LinkModel link;

  const ShareLinkSheet({super.key, required this.link});

  @override
  Widget build(BuildContext context) {
    return ShareRecipientSheet.link(link: link);
  }
}
