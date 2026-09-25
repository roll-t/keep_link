import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/services/backend/friend_connection_service.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/page/qr_scanner_page.dart';

Future<void> openAddFriendMethodsSheet(
  BuildContext context,
  FriendController controller,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.d500,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AddFriendMethodsSheet(
      onAddByGmail: () => openAddByGmailSheet(context, controller),
      onAddByLink: () => openAddByLinkSheet(context, controller),
    ),
  );
}

class AddFriendMethodsSheet extends StatelessWidget {
  const AddFriendMethodsSheet({
    super.key,
    required this.onAddByGmail,
    required this.onAddByLink,
  });

  final VoidCallback onAddByGmail;
  final VoidCallback onAddByLink;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.n500,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: 'Choose Add Friend Method'.tr,
              color: AppColors.white,
              size: 18,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 6),
            TextWidget(
              text: 'You can add friends by Gmail or personal link.'.tr,
              color: AppColors.n70,
              size: 13,
            ),
            const SizedBox(height: 16),
            MethodTile(
              icon: Icons.alternate_email_rounded,
              title: 'Add via Gmail'.tr,
              subtitle: 'Find a friend account with their Gmail.'.tr,
              onTap: () {
                Navigator.of(context).pop();
                onAddByGmail();
              },
            ),
            const SizedBox(height: 10),
            MethodTile(
              icon: Icons.link_rounded,
              title: 'Add via Link'.tr,
              subtitle: 'Paste your friend\'s personal link.'.tr,
              onTap: () {
                Navigator.of(context).pop();
                onAddByLink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MethodTile extends StatelessWidget {
  const MethodTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg700,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacityCompat(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: title,
                      color: AppColors.white,
                      size: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 2),
                    TextWidget(text: subtitle, color: AppColors.n70, size: 12),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.n500,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openAddByGmailSheet(
  BuildContext context,
  FriendController controller,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.d500,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AddFriendByGmailSheet(controller: controller),
  );
}

class AddFriendByGmailSheet extends StatefulWidget {
  const AddFriendByGmailSheet({super.key, required this.controller});

  final FriendController controller;

  @override
  State<AddFriendByGmailSheet> createState() => _AddFriendByGmailSheetState();
}

class _AddFriendByGmailSheetState extends State<AddFriendByGmailSheet> {
  final _emailCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      AppToast.showToast(
        'Please enter an email'.tr,
        Icons.warning_rounded,
        color: AppColors.warning,
      );
      return;
    }
    setState(() => _submitting = true);
    final success = await widget.controller.addFriendFromEmail(email);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.n500,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: 'Add via Gmail'.tr,
              color: AppColors.white,
              size: 18,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 6),
            TextWidget(
              text: 'Find a friend account with their Gmail.'.tr,
              color: AppColors.n70,
              size: 13,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'name@gmail.com',
                hintStyle: const TextStyle(color: AppColors.n500),
                filled: true,
                fillColor: AppColors.bg700,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : TextWidget(
                        text: 'Send Request'.tr,
                        color: AppColors.white,
                        size: 14,
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> openAddByLinkSheet(
  BuildContext context,
  FriendController controller,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.d500,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AddFriendByLinkSheet(controller: controller),
  );
}

class AddFriendByLinkSheet extends StatefulWidget {
  const AddFriendByLinkSheet({super.key, required this.controller});

  final FriendController controller;

  @override
  State<AddFriendByLinkSheet> createState() => _AddFriendByLinkSheetState();
}

class _AddFriendByLinkSheetState extends State<AddFriendByLinkSheet> {
  final _linkCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      _linkCtrl.text = text;
    }
  }

  Future<void> _submit() async {
    final raw = _linkCtrl.text.trim();
    if (raw.isEmpty) {
      AppToast.showToast(
        'Please enter a friend link'.tr,
        Icons.warning_rounded,
        color: AppColors.warning,
      );
      return;
    }

    final payload = FriendConnectionService.parseLink(raw);
    if (payload == null) {
      AppToast.showToast(
        'friend_invalid_link'.tr,
        Icons.error_outline_rounded,
        color: AppColors.error,
      );
      return;
    }

    final confirmed = await showFriendRequestConfirmSheet(context, payload);
    if (!confirmed || !mounted) return;

    setState(() => _submitting = true);
    final success = await widget.controller.addFriendFromLink(raw);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.n500,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: 'Add via Link'.tr,
              color: AppColors.white,
              size: 18,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 6),
            TextWidget(
              text: 'Paste your friend\'s personal link.'.tr,
              color: AppColors.n70,
              size: 13,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _linkCtrl,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'keeplink://open/friend?data=...',
                hintStyle: const TextStyle(color: AppColors.n500),
                filled: true,
                fillColor: AppColors.bg700,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.content_paste_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: _pasteFromClipboard,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : TextWidget(
                        text: 'Send Request'.tr,
                        color: AppColors.white,
                        size: 14,
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
