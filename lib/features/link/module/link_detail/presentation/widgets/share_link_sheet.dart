import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/image/cache_image.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

/// Bottom sheet that lets the user share/unshare an individual link with friends.
class ShareLinkSheet extends StatefulWidget {
  final LinkModel link;

  const ShareLinkSheet({super.key, required this.link});

  @override
  State<ShareLinkSheet> createState() => _ShareLinkSheetState();
}

class _ShareLinkSheetState extends State<ShareLinkSheet> {
  final RxSet<String> _sharedFriendUids = <String>{}.obs;
  final RxBool _isLoadingInitial = true.obs;
  final RxSet<String> _pendingToggles = <String>{}.obs;

  @override
  void initState() {
    super.initState();
    _loadSharedState();
  }

  Future<void> _loadSharedState() async {
    try {
      _isLoadingInitial.value = true;
      final uids = await FirebaseService.getLinkSharedFriendUids(widget.link.id);
      _sharedFriendUids.addAll(uids);
    } catch (_) {
    } finally {
      _isLoadingInitial.value = false;
    }
  }

  Future<void> _toggle(FriendModel friend) async {
    final uid = friend.friendUserId;
    if (_pendingToggles.contains(uid)) return;

    final wasShared = _sharedFriendUids.contains(uid);
    _pendingToggles.add(uid);

    try {
      if (wasShared) {
        await FirebaseService.unshareLink(friendUid: uid, linkId: widget.link.id);
        _sharedFriendUids.remove(uid);
        AppToast.showToast(
          'unshare_link_success'.tr,
          Icons.link_off_rounded,
          color: Colors.orange,
        );
      } else {
        await FirebaseService.shareLink(friendUid: uid, linkId: widget.link.id);
        _sharedFriendUids.add(uid);
        AppToast.showToast(
          'share_link_success'.tr,
          Icons.check_circle_rounded,
          color: Colors.green,
        );
      }
    } catch (_) {
      AppToast.showToast(
        'share_link_failed'.tr,
        Icons.error_outline_rounded,
        color: Colors.red,
      );
    } finally {
      _pendingToggles.remove(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.link.metaDataModel;
    final title = widget.link.name ?? meta?.title ?? 'Link';
    final imageUrl = meta?.imageUrl ?? '';

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.d500,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.n500.withOpacityCompat(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header with link summary
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    // Link thumbnail / icon
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CacheImageWidget(
                          imageUrl: imageUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacityCompat(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.link_rounded, color: AppColors.primary, size: 24),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: 'share_link'.tr,
                            color: AppColors.primary,
                            size: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          const SizedBox(height: 2),
                          TextWidget(
                            text: title,
                            color: AppColors.white,
                            size: 15,
                            fontWeight: FontWeight.w600,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: AppColors.n500.withOpacityCompat(0.2), height: 1),
              // Friends list
              Obx(() {
                if (_isLoadingInitial.value) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }

                if (FirebaseService.currentUser == null) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: TextWidget(
                      text: 'share_sign_in_required'.tr,
                      color: AppColors.n70,
                      size: 14,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final friendsList = AppCache.friends.toList();

                if (friendsList.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: TextWidget(
                      text: 'share_no_friends'.tr,
                      color: AppColors.n70,
                      size: 14,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: friendsList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final friend = friendsList[index];
                      final uid = friend.friendUserId;
                      return Obx(() {
                        final isShared = _sharedFriendUids.contains(uid);
                        final isPending = _pendingToggles.contains(uid);
                        return _FriendLinkShareRow(
                          friend: friend,
                          isShared: isShared,
                          isPending: isPending,
                          onTap: () => _toggle(friend),
                        );
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendLinkShareRow extends StatelessWidget {
  final FriendModel friend;
  final bool isShared;
  final bool isPending;
  final VoidCallback onTap;

  const _FriendLinkShareRow({
    required this.friend,
    required this.isShared,
    required this.isPending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = friend.photoUrl ?? '';
    return GestureDetector(
      onTap: isPending ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isShared ? AppColors.primary.withOpacityCompat(0.08) : AppColors.bg700,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isShared
                ? AppColors.primary.withOpacityCompat(0.3)
                : AppColors.n500.withOpacityCompat(0.18),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            photoUrl.isNotEmpty
                ? CacheImageWidget(
                    imageUrl: photoUrl,
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.circular(20),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacityCompat(0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: TextWidget(
                      text: friend.displayName.isNotEmpty
                          ? friend.displayName[0].toUpperCase()
                          : '?',
                      color: AppColors.primary,
                      size: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: friend.displayName,
                    color: AppColors.white,
                    size: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  if ((friend.email ?? '').isNotEmpty)
                    TextWidget(text: friend.email!, color: AppColors.n70, size: 12),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isPending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : Icon(
                    isShared ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: isShared ? AppColors.primary : AppColors.n500,
                    size: 24,
                  ),
          ],
        ),
      ),
    );
  }
}
