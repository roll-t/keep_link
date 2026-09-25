import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/features/category/presentation/controller/category_controller.dart';
import 'package:keep_link/features/category/presentation/widget/category_dialog.dart';
import 'package:keep_link/features/category/presentation/widget/custom_popup_widget.dart';
import 'package:keep_link/features/category/presentation/widget/share_category_sheet.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/header_link_collection_controller.dart';

class HeaderLinkCollection extends StatelessWidget {
  const HeaderLinkCollection({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<CategoryController>();
    final headerController = Get.find<HeaderLinkCollectionController>();
    final safeTop = MediaQuery.paddingOf(context).top;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, safeTop + 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Left: Friends icon ─────────────────────────────────────
          Obx(() {
            final isLoggedIn = FriendController.currentUser.value != null;
            final count = FriendController.pendingRequestCount.value;
            if (!isLoggedIn) return const SizedBox(width: 44, height: 44);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                AppVectors.icFriends.show(
                  size: 24,
                  backgroundColor: AppColors.navigationSurface,
                  padding: const EdgeInsets.all(10),
                  widthParent: 44,
                  onTap: headerController.openFriends,
                ),
                if (count > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.dangerBright,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(width: 12),

          // ── Middle: Category dropdown (flexible) ────────────────────
          Flexible(
            child: CustomPopupWidget(
              controller: categoryController.popupController,
              onSelected: categoryController.onSelectedCategory,
            ),
          ),
          const SizedBox(width: 12),

          // ── Right: Action buttons ────────────────────────────────────
          Obx(() {
            final isLoggedIn = FriendController.currentUser.value != null;
            final selected =
                categoryController.popupController.selectedItem.value;
            final showCategoryActions =
                selected?.id != 'all' &&
                categoryController.popupController.items.length > 1;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showCategoryActions) ...[
                  _CategoryMoreButton(
                    isLoggedIn: isLoggedIn,
                    categoryController: categoryController,
                  ),
                  const SizedBox(width: 8),
                ],
                AppVectors.icAdd.show(
                  size: 28,
                  backgroundColor: AppColors.navigationSurface,
                  padding: const EdgeInsets.all(8),
                  widthParent: 44,
                  onTap: () => Get.dialog(
                    const CategoryDialog(),
                    barrierDismissible: false,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Nút ⋮ chứa Edit + Share (nếu đã đăng nhập) cho category đang chọn
class _CategoryMoreButton extends StatelessWidget {
  const _CategoryMoreButton({
    required this.isLoggedIn,
    required this.categoryController,
  });

  final bool isLoggedIn;
  final CategoryController categoryController;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        final selected = categoryController.popupController.selectedItem.value;
        if (value == 'edit') {
          Get.dialog(
            const CategoryDialog(isEditMode: true),
            barrierDismissible: false,
          );
        } else if (value == 'pin' && selected != null && selected.id != 'all') {
          categoryController.togglePinCategory(selected.id!);
        } else if (value == 'visibility' &&
            selected != null &&
            selected.id != 'all') {
          categoryController.toggleCategoryVisibility(selected.id!);
        } else if (value == 'share' &&
            selected != null &&
            selected.id != 'all') {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.transparent,
            builder: (_) => ShareCategorySheet(
              categoryId: selected.id ?? '',
              categoryName: selected.name ?? '',
            ),
          );
        } else if (value == 'delete') {
          categoryController.deleteCategory();
        }
      },
      color: AppColors.navigationSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      borderRadius: BorderRadius.circular(22),
      offset: const Offset(30, 55),
      itemBuilder: (_) {
        final selected = categoryController.popupController.selectedItem.value;
        final isPinned = categoryController.isCategoryPinned(selected?.id);
        final isPrivate = selected?.visibility == VisibilityStatus.private;
        final canToggleVisibility =
            AppGetStorage.isCategorySecurity() &&
            selected != null &&
            selected.id != 'all';
        return [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: AppColors.white,
                ),
                const SizedBox(width: 10),
                Text('Edit'.tr, style: const TextStyle(color: AppColors.white)),
              ],
            ),
          ),
          if (selected != null && selected.id != 'all')
            PopupMenuItem(
              value: 'pin',
              child: Row(
                children: [
                  Icon(
                    isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    size: 18,
                    color: isPinned ? AppColors.successBright : AppColors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isPinned ? 'Bỏ ghim' : 'Ghim',
                    style: TextStyle(
                      color: isPinned
                          ? AppColors.successBright
                          : AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          if (canToggleVisibility)
            PopupMenuItem(
              value: 'visibility',
              child: Row(
                children: [
                  Icon(
                    isPrivate ? Icons.public : Icons.lock_rounded,
                    size: 18,
                    color: isPrivate ? AppColors.white : AppColors.amber,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isPrivate ? 'Đặt công khai' : 'Đặt riêng tư',
                    style: TextStyle(
                      color: isPrivate ? AppColors.white : AppColors.amber,
                    ),
                  ),
                ],
              ),
            ),
          if (isLoggedIn)
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  AppVectors.icSharedCategory.show(
                    size: 18,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Share'.tr,
                    style: const TextStyle(color: AppColors.white),
                  ),
                ],
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(
                  Icons.delete_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                const SizedBox(width: 10),
                Text(
                  'Delete'.tr,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
            ),
          ),
        ];
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.navigationSurface,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          size: 22,
          color: AppColors.white,
        ),
      ),
    );
  }
}
