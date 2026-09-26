import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/link_detail_controller.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/change_category_sheet.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/destination_card.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/hero_media_widget.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/share_link_sheet.dart';

class LinkDetailPage extends StatelessWidget {
  static const routeName = '/LinkDetailPage';

  final LinkModel? link;
  final bool readOnly;
  const LinkDetailPage({super.key, this.link, this.readOnly = false});

  LinkDetailController get _controller {
    final raw = Get.arguments;
    final args = link != null
        ? LinkDetailArguments(link: link!, readOnly: readOnly)
        : raw is LinkDetailArguments
        ? raw
        : LinkDetailArguments(link: raw as LinkModel);
    if (Get.isRegistered<LinkDetailController>()) {
      final existing = Get.find<LinkDetailController>();
      if (existing.link.id == args.link.id && existing.readOnly == args.readOnly) {
        return existing;
      }
      Get.delete<LinkDetailController>();
    }
    return Get.put(LinkDetailController(link: args.link, readOnly: args.readOnly));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return SafeArea(
      top: false,
      child: Obx(() {
        final isFullscreenPlayer = controller.isPlayingVideo.value && controller.isExpanded.value;

        return Scaffold(
          backgroundColor: AppColors.surfaceDeep,
          // Đang xem webview toàn màn hình: ẩn hẳn appbar (share/xoá/sửa +
          // nút back) — thanh điều hướng riêng của webview đã có nút X để
          // thoát, hai nút "đóng" chồng nhau dễ bấm nhầm khi đang đọc.
          appBar: isFullscreenPlayer ? null : _buildAppBar(context, controller),
          // Không có appBar (đã ẩn ở trên) nên không còn ai tự lo phần status
          // bar nữa — phải tự bọc SafeArea(top: true) ở đây, nếu không thanh
          // điều hướng webview sẽ bị đồng hồ/icon status bar đè lên.
          body: isFullscreenPlayer
              ? const SafeArea(top: true, bottom: false, child: HeroMediaWidget())
              : _buildDetailBody(context, controller),
        );
      }),
    );
  }

  Widget _buildDetailBody(BuildContext context, LinkDetailController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HeroMediaWidget(),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.title.isNotEmpty)
                  TextWidget(
                    text: controller.title,
                    textStyle: AppTextStyle.bold20,
                    color: AppColors.white,
                    maxLines: 2,
                  ),
                if (controller.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextWidget(
                    text: controller.description,
                    textStyle: AppTextStyle.regular12,
                    color: AppColors.mediaTextMuted,
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 16),
                _buildCategoryCard(context, controller),
                const SizedBox(height: 8),
                const DestinationCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, LinkDetailController controller) {
    return Obx(() {
      final category = controller.currentCategory;
      final hasCategory = category != null;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (controller.readOnly) {
            controller.showReadOnlyMessage();
            return;
          }
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.transparent,
            builder: (_) => ChangeCategorySheet(controller: controller),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.folder_outlined, color: AppColors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextWidget(
                            text: hasCategory ? (category.name ?? "Folder".tr) : "Folder".tr,
                            textStyle: AppTextStyle.semiBold16,
                            color: AppColors.white,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextWidget(
                      text: hasCategory
                          ? "Tap to move to another category".tr
                          : "Add this post to a category".tr,
                      textStyle: AppTextStyle.regular12,
                      color: AppColors.grey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  hasCategory ? Icons.drive_file_move_outlined : Icons.create_new_folder_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, LinkDetailController controller) {
    return AppBar(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 20),
        onPressed: () => Get.back(),
      ),
      centerTitle: true,
      actions: controller.readOnly
          ? const []
          : [
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.transparent,
                    builder: (_) => ShareLinkSheet(link: controller.link),
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
                onTap: controller.deleteLink,
              ),
              const SizedBox(width: 16),
            ],
    );
  }
}

enum _MenuAction {
  open,
  edit,
  delete;

  void execute(LinkDetailController controller) {
    switch (this) {
      case _MenuAction.open:
        controller.openInApp();
      case _MenuAction.edit:
        controller.goToEdit();
      case _MenuAction.delete:
        controller.deleteLink();
    }
  }
}
