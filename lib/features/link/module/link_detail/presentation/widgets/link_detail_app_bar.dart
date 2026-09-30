import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/link_detail_controller.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/share_link_sheet.dart';

class LinkDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final LinkDetailController? controller;

  const LinkDetailAppBar({super.key, this.controller});

  LinkDetailController get _effectiveController =>
      controller ?? Get.find<LinkDetailController>();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final ctrl = _effectiveController;

    return AppBar(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 20),
        onPressed: () => Get.back(),
      ),
      centerTitle: true,
      actions: ctrl.readOnly
          ? const []
          : [
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.transparent,
                    builder: (_) => ShareLinkSheet(link: ctrl.link),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.bg500, shape: BoxShape.circle),
                  child: AppVectors.icSharedCategory.show(size: 18, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              AppVectors.icDelete.show(
                backgroundColor: AppColors.bg500,
                padding: const EdgeInsets.all(8),
                color: AppColors.error,
                onTap: ctrl.deleteLink,
              ),
              const SizedBox(width: 16),
            ],
    );
  }
}
