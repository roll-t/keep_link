import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/cache/app_cache.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/library/custom_popup.dart';
import 'package:keep_link/core/model/item_model.dart';
import 'package:keep_link/core/ui/image/cache_image.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/category/presentation/controller/custom_popup_controller.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';

class CustomPopupWidget extends StatelessWidget {
  final VoidCallback? onSelected;
  final CustomPopupController controller;
  final bool hasAll;

  const CustomPopupWidget({
    super.key,
    required this.controller,
    this.onSelected,
    this.hasAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      constraints: BoxConstraints(minWidth: Get.width * .3, maxWidth: Get.width * .45),
      decoration: BoxDecoration(color: AppColors.d300, borderRadius: BorderRadius.circular(100)),
      alignment: Alignment.center,
      child: Obx(() {
        String nameWithCount(ItemModel? item, String fallback) {
          if (item == null) return fallback;
          final base = item.name ?? fallback;
          if (item.id == 'all') return base;
          final count = item.chilrenCount;
          return count != null ? '$base ($count)' : base;
        }

        final RxString displayTitle =
            (hasAll
                    ? nameWithCount(controller.selectedItem.value, "Select Category".tr)
                    : (controller.selectedItem.value?.id == 'all'
                          ? "Select Category".tr
                          : nameWithCount(controller.selectedItem.value, "Select Category".tr)))
                .obs;
        return CustomPopup(
          barrierColor: Colors.transparent,
          showArrow: false,
          arrowColor: AppColors.white,
          position: PopupPosition.bottom,
          onAfterPopup: () => controller.isOpen.value = false,
          onBeforePopup: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.isOpen.value = true;
              controller.scrollToSelected();
            });
          },

          // ===== POPUP CONTENT =====
          contentDecoration: BoxDecoration(
            color: AppColors.d200,
            borderRadius: BorderRadius.circular(12),
          ),
          content: Builder(
            builder: (context) {
              final displayItems = hasAll
                  ? controller.items
                  : controller.items.where((e) => e.id != 'all').toList();

              return Container(
                width: Get.width * .7,
                constraints: BoxConstraints(
                  maxHeight: displayItems.length > controller.maxItemDisplay
                      ? controller.itemHeight * controller.maxItemDisplay
                      : displayItems.length * controller.itemHeight,
                ),
                child: ListView.builder(
                  controller: controller.scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: displayItems.length,
                  itemBuilder: (context, index) {
                    final item = displayItems[index];
                    final isSelected = controller.selectedItem.value?.id == item.id;
                    final isLastItem = index == displayItems.length - 1;
                    return GestureDetector(
                      onTap: () async {
                        await controller.selectItem(item);
                        Navigator.of(context).pop();
                        onSelected?.call();
                      },
                      child: Container(
                        height: controller.itemHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          border: !isLastItem
                              ? Border(bottom: BorderSide(color: AppColors.d100))
                              : null,
                          color: isSelected ? AppColors.d100 : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: TextWidget(
                                text: item.id == 'all'
                                    ? (item.name ?? '')
                                    : (item.chilrenCount != null
                                          ? '${item.name ?? ''} (${item.chilrenCount})'
                                          : (item.name ?? '')),
                                maxLines: 1,
                                textStyle: AppTextStyle.semiBold16,
                              ),
                            ),
                            if (item.visibility == VisibilityStatus.private &&
                                controller.isEnableSecurity)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(Icons.lock, size: 16, color: AppColors.t300),
                              ),
                            // Shared avatars + share-status icon (only for real categories, not "all")
                            if (item.id != null && item.id != 'all')
                              Obx(() {
                                final isLoggedIn = FriendController.currentUser.value != null;
                                final isPinned = item.isPinned;
                                if (!isLoggedIn && !isPinned) return const SizedBox.shrink();
                                final friends = AppCache.sharedWithCache[item.id] ?? [];
                                final isSharedOut = friends.isNotEmpty;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isPinned) ...[
                                      const Icon(
                                        Icons.push_pin_rounded,
                                        size: 14,
                                        color: Color(0xFF4CAF50),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    if (isLoggedIn) ...[
                                      if (isSharedOut) ...[
                                        _SharedAvatarRow(friends: friends),
                                        const SizedBox(width: 4),
                                      ],
                                      _ShareStatusIcon(isSharedOut: isSharedOut),
                                    ],
                                  ],
                                );
                              }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // ===== BUTTON =====
          child: Container(
            padding: const EdgeInsets.only(left: 14, right: 8),
            height: controller.itemHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextWidget(
                    text: displayTitle.value,
                    maxLines: 1,
                    textStyle: AppTextStyle.semiBold16,
                  ),
                ),
                Obx(() {
                  return AnimatedRotation(
                    turns: controller.isOpen.value ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: AppVectors.icArrowDown.show(color: AppColors.t300),
                  );
                }),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Share-status icon ─────────────────────────────────────────────────────────

/// Icon ngoài cùng bên phải:
/// - [isSharedOut] = true  → đã chia sẻ với bạn bè (arrow 45° hướng lên, xanh lá)
/// - [isSharedOut] = false → chưa chia sẻ (xám)
class _ShareStatusIcon extends StatelessWidget {
  const _ShareStatusIcon({required this.isSharedOut});

  final bool isSharedOut;

  @override
  Widget build(BuildContext context) {
    if (!isSharedOut) return const SizedBox.shrink();
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withAlpha(40),
        shape: BoxShape.circle,
      ),
      child: Transform.rotate(
        angle: 0.785398,
        child: const Icon(Icons.arrow_upward_rounded, size: 13, color: Color(0xFF4CAF50)),
      ),
    );
  }
}

// ── Shared-avatar row ─────────────────────────────────────────────────────────

class _SharedAvatarRow extends StatelessWidget {
  const _SharedAvatarRow({required this.friends});

  final List<FriendModel> friends;

  static const double _size = 20.0;
  static const int _maxVisible = 2;

  @override
  Widget build(BuildContext context) {
    final visible = friends.take(_maxVisible).toList();
    final extra = friends.length - _maxVisible;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visible.map((f) => _Avatar(friend: f, size: _size)),
        if (extra > 0) ...[
          const SizedBox(width: 3),
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(50),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '+$extra',
              style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.friend, required this.size});

  final FriendModel friend;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = friend.photoUrl ?? '';
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: url.isNotEmpty ? AppColors.d300 : AppColors.primary, width: .5),
        ),
        child: ClipOval(
          child: url.isNotEmpty
              ? CacheImageWidget(imageUrl: url, width: size, height: size)
              : Icon(Icons.people, size: size * 0.6, color: AppColors.primary),
        ),
      ),
    );
  }
}
