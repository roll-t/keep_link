import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/link_detail_controller.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/destination_card.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/hero_media_widget.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/share_link_sheet.dart';

class LinkDetailPage extends StatelessWidget {
  static const routeName = '/LinkDetailPage';

  final LinkModel? link;
  const LinkDetailPage({super.key, this.link});

  LinkDetailController get _controller {
    final effectiveLink = link ?? (Get.arguments as LinkModel);
    if (Get.isRegistered<LinkDetailController>()) {
      final existing = Get.find<LinkDetailController>();
      if (existing.link.id == effectiveLink.id) return existing;
      Get.delete<LinkDetailController>();
    }
    return Get.put(LinkDetailController(link: effectiveLink));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return SafeArea(
      top: false,
      child: Obx(() {
        final isFullscreenPlayer = controller.isPlayingVideo.value && controller.isExpanded.value;

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          // Đang xem webview toàn màn hình: ẩn hẳn appbar (share/xoá/sửa +
          // nút back) — thanh điều hướng riêng của webview đã có nút X để
          // thoát, hai nút "đóng" chồng nhau dễ bấm nhầm khi đang đọc.
          appBar: isFullscreenPlayer ? null : _buildAppBar(context, controller),
          // Không có appBar (đã ẩn ở trên) nên không còn ai tự lo phần status
          // bar nữa — phải tự bọc SafeArea(top: true) ở đây, nếu không thanh
          // điều hướng webview sẽ bị đồng hồ/icon status bar đè lên.
          body: isFullscreenPlayer
              ? const SafeArea(top: true, bottom: false, child: HeroMediaWidget())
              : _buildDetailBody(controller),
        );
      }),
    );
  }

  Widget _buildDetailBody(LinkDetailController controller) {
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
                    textStyle: AppTextStyle.bold22,
                    color: Colors.white,
                    maxLines: 2,
                  ),
                const SizedBox(height: 8),
                if (controller.description.isNotEmpty)
                  TextWidget(
                    text: controller.description,
                    textStyle: AppTextStyle.regular12,
                    color: const Color(0xFFA0A0A0),
                    maxLines: 3,
                  ),
                const SizedBox(height: 18),
                const DestinationCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, LinkDetailController controller) {
    return AppBar(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Get.back(),
      ),
      centerTitle: true,
      actions: [
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ShareLinkSheet(link: controller.link),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppColors.bg500, shape: BoxShape.circle),
            child: const Icon(Icons.share_rounded, size: 18, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 12),
        AppVectors.icDelete.show(
          backgroundColor: AppColors.bg500,
          padding: const EdgeInsets.all(8),
          color: AppColors.red,
          onTap: controller.deleteLink,
        ),
        const SizedBox(width: 12),
        AppVectors.icEdit.show(
          backgroundColor: AppColors.bg500,
          padding: const EdgeInsets.all(8),
          onTap: controller.goToEdit,
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

// class _MoreMenu extends StatelessWidget {
//   final LinkDetailController controller;
//   const _MoreMenu({required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     return Theme(
//       data: Theme.of(
//         context,
//       ).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
//       child: PopupMenuButton<_MenuAction>(
//         icon: const Icon(Icons.more_vert_outlined, color: Colors.white),
//         color: const Color(0xFF1E1E1E),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         position: PopupMenuPosition.under,
//         onSelected: (action) => action.execute(controller),
//         itemBuilder: (_) => const [
//           PopupMenuItem(
//             value: _MenuAction.open,
//             child: _MenuRow(Icons.open_in_new, "Open in App", AppColors.white),
//           ),
//           PopupMenuItem(
//             value: _MenuAction.edit,
//             child: _MenuRow(Icons.edit, "Edit Link", Colors.white),
//           ),
//           PopupMenuDivider(),
//           PopupMenuItem(
//             value: _MenuAction.delete,
//             child: _MenuRow(Icons.delete_outline, "Remove Link", AppColors.red),
//           ),
//         ],
//       ),
//     );
//   }
// }

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
