import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/cache/app_cache.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/core/service/firebase_service.dart';
import 'package:keep_link/core/ui/image/cache_image.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/category/presentation/controller/category_controller.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';

/// Bottom sheet that lets the user share/unshare the currently selected
/// category with each of their friends.
class ShareCategorySheet extends StatefulWidget {
  const ShareCategorySheet({super.key, required this.categoryId, required this.categoryName});

  final String categoryId;
  final String categoryName;

  @override
  State<ShareCategorySheet> createState() => _ShareCategorySheetState();
}

class _ShareCategorySheetState extends State<ShareCategorySheet> {
  late final CategoryController _categoryCtrl;
  final RxSet<String> _sharedFriendUids = <String>{}.obs;
  final RxBool _isLoadingInitial = true.obs;
  final RxSet<String> _pendingToggles = <String>{}.obs;

  @override
  void initState() {
    super.initState();
    _categoryCtrl = Get.find<CategoryController>();
    _loadSharedState();
  }

  Future<void> _loadSharedState() async {
    try {
      _isLoadingInitial.value = true;
      final uids = await FirebaseService.getCategorySharedFriendUids(widget.categoryId);
      _sharedFriendUids.addAll(uids);
    } finally {
      _isLoadingInitial.value = false;
    }
  }

  Future<void> _toggle(FriendModel friend) async {
    final uid = friend.friendUserId;
    if (_pendingToggles.contains(uid)) return;

    final wasShared = _sharedFriendUids.contains(uid);
    _pendingToggles.add(uid);

    await _categoryCtrl.toggleCategoryShare(
      categoryId: widget.categoryId,
      friend: friend,
      currentlyShared: wasShared,
      onSuccess: () {
        if (wasShared) {
          _sharedFriendUids.remove(uid);
        } else {
          _sharedFriendUids.add(uid);
        }
      },
    );

    _pendingToggles.remove(uid);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
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
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.share_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: 'share_category'.tr,
                          color: AppColors.white,
                          size: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        TextWidget(text: widget.categoryName, color: AppColors.n70, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  shrinkWrap: true,
                  itemCount: friendsList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final friend = friendsList[index];
                    final uid = friend.friendUserId;
                    return Obx(() {
                      final isShared = _sharedFriendUids.contains(uid);
                      final isPending = _pendingToggles.contains(uid);
                      return _FriendShareRow(
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
    );
  }
}

class _FriendShareRow extends StatelessWidget {
  const _FriendShareRow({
    required this.friend,
    required this.isShared,
    required this.isPending,
    required this.onTap,
  });

  final FriendModel friend;
  final bool isShared;
  final bool isPending;
  final VoidCallback onTap;

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
