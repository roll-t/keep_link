import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/link_detail_controller.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/destination_card.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/hero_media_widget.dart';

class LinkDetailPage extends StatelessWidget {
  final LinkModel link;
  const LinkDetailPage({super.key, required this.link});
  LinkDetailController get _controller => Get.put(LinkDetailController(link: link));

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * .9,
          minHeight: MediaQuery.of(context).size.height * .5,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: _buildAppBar(context, controller),
          body: Obx(() {
            // While the webview player is expanded it needs the full body
            // height (it fills via Expanded, no fixed height of its own —
            // see _ExpandedWebView). Keeping the info section mounted below
            // it here would force the Column to lay out more content than
            // the sheet's own maxHeight allows, overflowing the bottom edge.
            final isFullscreenPlayer = controller.isPlayingVideo.value && controller.isExpanded.value;

            // Scaffold.body already receives bounded constraints filling the
            // whole body area, so HeroMediaWidget can go straight in here —
            // wrapping it in Expanded would be invalid outside a Flex parent.
            if (isFullscreenPlayer) {
              return const HeroMediaWidget();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeroMediaWidget(),
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
                        DestinationCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, LinkDetailController controller) {
    return AppBar(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      leadingWidth: 56,
      leading: const CloseButton(color: Colors.white),
      title: _DragHandle(),
      centerTitle: true,
      actions: [
        AppVectors.icDelete.show(
          backgroundColor: AppColors.bg500,
          padding: EdgeInsets.all(8),
          color: AppColors.red,
          onTap: controller.deleteLink,
        ),

        SizedBox(width: 12),
        AppVectors.icEdit.show(
          backgroundColor: AppColors.bg500,
          padding: EdgeInsets.all(8),
          onTap: controller.goToEdit,
        ),
        SizedBox(width: 16),
        // _MoreMenu(controller: controller)
      ], // Giữ nguyên popup menu của bạn
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

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 5,
    decoration: BoxDecoration(
      color: AppColors.grey.withOpacityCompat(0.3),
      borderRadius: BorderRadius.circular(10),
    ),
  );
}
