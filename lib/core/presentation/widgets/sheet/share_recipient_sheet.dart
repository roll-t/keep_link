import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_edge_insets.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/appbar/sheet_header.dart';
import 'package:keep_link/core/presentation/widgets/image/cache_image.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/presentation/widgets/text_field/search_input_field.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:share_plus/share_plus.dart';

/// Bottom sheet chung dùng cho luồng chia sẻ Liên kết (Link) và Danh mục (Category)
/// tới bạn bè trong ứng dụng hoặc chia sẻ qua ứng dụng khác.
class ShareRecipientSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? shareUrl;
  final Future<List<String>> Function() onGetSharedUids;
  final Future<void> Function({
    required Set<String> toShare,
    required Set<String> toRemove,
    required String message,
  })
  onConfirmShare;
  final String successShareMessage;
  final String successUnshareMessage;
  final String errorMessage;

  const ShareRecipientSheet({
    super.key,
    required this.title,
    required this.subtitle,
    this.shareUrl,
    required this.onGetSharedUids,
    required this.onConfirmShare,
    required this.successShareMessage,
    required this.successUnshareMessage,
    required this.errorMessage,
  });

  /// Factory chia sẻ Link
  factory ShareRecipientSheet.link({Key? key, required LinkModel link}) {
    final meta = link.metaDataModel;
    final name = link.name?.trim();
    final metaTitle = meta?.title.trim();
    final title = (name != null && name.isNotEmpty)
        ? name
        : ((metaTitle != null && metaTitle.isNotEmpty) ? metaTitle : 'Link');
    final url = meta?.url ?? '';

    return ShareRecipientSheet(
      key: key,
      title: 'share_send_to'.tr,
      subtitle: title,
      shareUrl: url.isNotEmpty ? url : null,
      onGetSharedUids: () => FirebaseService.getLinkSharedFriendUids(link.id),
      onConfirmShare:
          ({required toShare, required toRemove, required message}) async {
            for (final uid in toRemove) {
              await FirebaseService.unshareLink(
                friendUid: uid,
                linkId: link.id,
              );
            }
            for (final uid in toShare) {
              await FirebaseService.shareLink(
                friendUid: uid,
                linkId: link.id,
                message: message,
              );
            }
          },
      successShareMessage: 'share_link_success'.tr,
      successUnshareMessage: 'unshare_link_success'.tr,
      errorMessage: 'share_link_failed'.tr,
    );
  }

  /// Factory chia sẻ Danh mục
  factory ShareRecipientSheet.category({
    Key? key,
    required String categoryId,
    required String categoryName,
  }) {
    return ShareRecipientSheet(
      key: key,
      title: 'share_send_to'.tr,
      subtitle: categoryName,
      shareUrl: null,
      onGetSharedUids: () =>
          FirebaseService.getCategorySharedFriendUids(categoryId),
      onConfirmShare:
          ({required toShare, required toRemove, required message}) async {
            final friendsByUid = {
              for (final friend in AppCache.friends)
                friend.friendUserId: friend,
            };
            for (final uid in toRemove) {
              await FirebaseService.unshareCategory(
                friendUid: uid,
                categoryId: categoryId,
              );
              AppCache.removeSharedFriend(categoryId, uid);
            }
            for (final uid in toShare) {
              final friend = friendsByUid[uid];
              if (friend == null) continue;
              await FirebaseService.shareCategory(
                friendUid: uid,
                categoryId: categoryId,
                message: message,
              );
              AppCache.addSharedFriend(categoryId, friend);
            }
          },
      successShareMessage: 'category_shared'.tr,
      successUnshareMessage: 'category_unshared'.tr,
      errorMessage: 'share_update_failed'.tr,
    );
  }

  @override
  State<ShareRecipientSheet> createState() => _ShareRecipientSheetState();
}

class _ShareRecipientSheetState extends State<ShareRecipientSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final Set<String> _initialSharedUids = <String>{};
  final Set<String> _selectedUids = <String>{};

  bool _isLoading = true;
  bool _isSending = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadSharedState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadSharedState() async {
    try {
      final uids = await widget.onGetSharedUids();
      if (!mounted) return;
      setState(() {
        _initialSharedUids.addAll(uids);
        _selectedUids.addAll(uids);
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<FriendModel> _filteredFriends(List<FriendModel> friends) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return friends;
    return friends.where((friend) {
      return friend.displayName.toLowerCase().contains(query) ||
          (friend.email?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _toggleSelection(String uid) {
    if (_isSending) return;
    setState(() {
      if (!_selectedUids.add(uid)) _selectedUids.remove(uid);
    });
  }

  bool get _hasChanges {
    return !_selectedUids.containsAll(_initialSharedUids) ||
        !_initialSharedUids.containsAll(_selectedUids) ||
        _messageController.text.trim().isNotEmpty;
  }

  bool get _canSubmit => _selectedUids.isNotEmpty || _hasChanges;

  Future<void> _send() async {
    if (_isSending || !_canSubmit) return;
    if (_selectedUids.isEmpty && _initialSharedUids.isEmpty) {
      Fluttertoast.showToast(msg: 'share_select_recipient'.tr);
      return;
    }

    final message = _messageController.text.trim();
    final toRemove = _initialSharedUids.difference(_selectedUids);
    final toShare = _selectedUids.difference(_initialSharedUids).toSet();
    if (message.isNotEmpty) toShare.addAll(_selectedUids);

    setState(() => _isSending = true);
    var failed = false;

    try {
      await widget.onConfirmShare(
        toShare: toShare,
        toRemove: toRemove,
        message: message,
      );
      _initialSharedUids
        ..removeAll(toRemove)
        ..addAll(toShare);
    } catch (_) {
      failed = true;
    }

    if (!mounted) return;
    setState(() => _isSending = false);
    if (failed) {
      Fluttertoast.showToast(msg: widget.errorMessage);
      return;
    }

    Fluttertoast.showToast(
      msg: _selectedUids.isEmpty
          ? widget.successUnshareMessage
          : widget.successShareMessage,
    );
    Navigator.of(context).pop();
  }

  void _onOtherPressed() {
    if (widget.shareUrl != null && widget.shareUrl!.isNotEmpty) {
      Share.share(widget.shareUrl!);
    } else {
      Fluttertoast.showToast(msg: 'share_other_hint'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: media.size.height * 0.88,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const _SheetHandle(),
                _buildHeader(),
                const SizedBox(height: 4),
                _buildSearch(),
                const SizedBox(height: 12),
                Expanded(child: _buildFriends()),
                _buildComposer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SheetHeader(
      title: widget.title,
      subtitle: widget.subtitle,
      trailing: TextButton(
        onPressed: _onOtherPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: TextWidget(
          text: 'share_other'.tr,
          color: AppColors.primaryDim,
          textStyle: AppTextStyle.semiBold14,
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: AppEdgeInsets.h20,
      child: SearchInputField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        hintText: 'share_search'.tr,
        height: 38,
        borderRadius: 20,
        backgroundColor: AppColors.d300,
      ),
    );
  }

  Widget _buildFriends() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (FirebaseService.currentUser == null) {
      return _EmptyState(text: 'share_sign_in_required'.tr);
    }

    return Obx(() {
      final friends = _filteredFriends(AppCache.friends.toList());
      if (friends.isEmpty) {
        return _EmptyState(
          text: _query.trim().isEmpty
              ? 'share_no_friends'.tr
              : 'no_friend_search_results'.tr,
        );
      }

      return GridView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 18,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
        itemCount: friends.length,
        itemBuilder: (_, index) {
          final friend = friends[index];
          return _FriendRecipientTile(
            friend: friend,
            selected: _selectedUids.contains(friend.friendUserId),
            enabled: !_isSending,
            onTap: () => _toggleSelection(friend.friendUserId),
          );
        },
      );
    });
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.n500.withOpacityCompat(0.2)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: TextField(
              controller: _messageController,
              onChanged: (_) => setState(() {}),
              enabled: !_isSending,
              maxLength: 200,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'share_message_hint'.tr,
                hintStyle: const TextStyle(
                  color: AppColors.n70,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                counterText: '',
                filled: true,
                fillColor: AppColors.d300,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: _canSubmit && !_isSending ? _send : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.n500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 18),
                        const SizedBox(width: 8),
                        TextWidget(
                          text: 'share_send'.tr,
                          color: AppColors.white,
                          textStyle: AppTextStyle.bold16,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 2),
      child: Container(
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.n70.withOpacityCompat(0.55),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _FriendRecipientTile extends StatelessWidget {
  const _FriendRecipientTile({
    required this.friend,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final FriendModel friend;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const avatarSize = 68.0;
    final photoUrl = friend.photoUrl ?? '';
    return Semantics(
      button: true,
      selected: selected,
      label: friend.displayName,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.transparent,
                        width: 2,
                      ),
                    ),
                    child: photoUrl.isNotEmpty
                        ? CacheImageWidget(
                            imageUrl: photoUrl,
                            width: avatarSize,
                            height: avatarSize,
                            borderRadius: BorderRadius.circular(avatarSize / 2),
                          )
                        : Container(
                            width: avatarSize,
                            height: avatarSize,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacityCompat(0.3),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: TextWidget(
                              text: friend.displayName.isNotEmpty
                                  ? friend.displayName[0].toUpperCase()
                                  : '?',
                              color: AppColors.white,
                              textStyle: AppTextStyle.semiBold24,
                            ),
                          ),
                  ),
                  if (selected)
                    Positioned(
                      right: -1,
                      bottom: 1,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              TextWidget(
                text: friend.displayName,
                color: AppColors.white,
                textStyle: AppTextStyle.medium12,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: TextWidget(
          text: text,
          color: AppColors.n70,
          textStyle: AppTextStyle.regular14,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
