import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/list_title_widget.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/page/shared_categories_page.dart';
import 'package:keep_link/features/friend/presentation/widgets/share_link_to_friend_sheet.dart';
import 'package:keep_link/features/friend/presentation/widgets/shared_categories_tab.dart';

/// Tab 2: Friends Management View
class FriendsManageTab extends StatelessWidget {
  const FriendsManageTab({
    super.key,
    required this.controller,
    required this.onRefresh,
    required this.onOpenRequests,
  });

  final FriendController controller;
  final RefreshCallback onRefresh;
  final VoidCallback onOpenRequests;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.d500,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ── Quick Action Card (Friend Requests) ─────────────────────────
          Obx(() {
            final reqCount = controller.incomingRequests.length;
            return ZaloTile(
              icon: Icons.group_add_rounded,
              iconColor: AppColors.white,
              iconBgColor: AppColors.brand,
              title: 'Friend Requests'.tr,
              subtitle: reqCount > 0
                  ? '$reqCount ${'requests_pending'.tr}'
                  : null,
              badgeCount: reqCount,
              onTap: onOpenRequests,
            );
          }),
          Divider(
            height: 1,
            thickness: 1,
            indent: 74,
            color: AppColors.white.withOpacityCompat(.06),
          ),
          // ── Section Title: Friends List ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Obx(
              () => TextWidget(
                text:
                    '${'Friends'.tr} (${controller.totalFriends}/${FriendController.maxFriends})',
                color: AppColors.white,
                textStyle: AppTextStyle.bold16,
              ),
            ),
          ),
          // ── Friends List Items ───────────────────────────────────────────
          Obx(() {
            final friends = controller.visibleFriends;
            if (controller.isLoading.value && friends.isEmpty) {
              return const FriendsLoadingView();
            }
            if (controller.errorMessage.value != null && friends.isEmpty) {
              return SharedErrorView(
                message: controller.errorMessage.value!,
                onRetry: controller.fetchFriends,
              );
            }
            if (friends.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.people_outline_rounded,
                        size: 48,
                        color: AppColors.n500,
                      ),
                      const SizedBox(height: 12),
                      TextWidget(
                        text: 'No friends found'.tr,
                        color: AppColors.n70,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: friends.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (_, index) {
                final friend = friends[index];
                return FriendItem(
                  friend: friend,
                  onShareLink: () =>
                      openShareLinkToFriendSheet(context, friend),
                  onDelete: () => controller.confirmDeleteFriend(friend),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class ZaloTile extends StatelessWidget {
  const ZaloTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    this.subtitle,
    this.badgeCount = 0,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String? subtitle;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: title,
                      color: AppColors.white,
                      size: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      TextWidget(
                        text: subtitle!,
                        color: AppColors.n70,
                        size: 12,
                      ),
                    ],
                  ],
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextWidget(
                    text: '$badgeCount',
                    color: AppColors.white,
                    size: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.n500,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FriendItem extends StatelessWidget {
  const FriendItem({
    super.key,
    required this.friend,
    required this.onShareLink,
    required this.onDelete,
  });

  final FriendModel friend;
  final VoidCallback onShareLink;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onShareLink,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SharedOwnerAvatar(
                    displayName: friend.displayName,
                    photoUrl: friend.photoUrl,
                    size: 48,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ListTitleWidget(
                  title: friend.displayName,
                  contentPadding: EdgeInsets.zero,
                  subtitle: (friend.email ?? '').isNotEmpty
                      ? friend.email!
                      : (friend.sourceLink ?? 'friend'.tr),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.surfaceContainerHighest,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onShareLink,
                  customBorder: const CircleBorder(),
                  child: AppVectors.icShareLink.show(
                    padding: const EdgeInsets.all(6),
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                tooltip: 'Tùy chọn',
                color: AppColors.d300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.n70,
                  size: 22,
                ),
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_remove_outlined,
                          color: AppColors.error,
                          size: 19,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Xóa bạn',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FriendsLoadingView extends StatelessWidget {
  const FriendsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: SizedBox.square(
          dimension: 26,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }
}
