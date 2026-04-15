import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/link/application/controller/link_detail_controller.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/presentation/link_detail/widgets/destination_card.dart';
import 'package:keep_link/features/link/presentation/link_detail/widgets/hero_media_widget.dart';
import 'package:keep_link/features/link/presentation/link_detail/widgets/link_tags_row.dart';

class LinkDetailPage extends StatelessWidget {
  final LinkModel link;
  const LinkDetailPage({super.key, required this.link});

  @override
  Widget build(BuildContext context) {
    Get.put(LinkDetailController(link: link));
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * .9,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.transparent,
            elevation: 0,
            title: _DragHandle(),
            leading: SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerLeft,
                child: const CloseButton(color: Colors.white),
              ),
            ),
            actions: [
              SizedBox(
                width: 80,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                    ), // Chỉnh lại padding 1 chút cho cân đối
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        // Tùy chỉnh màu hiệu ứng khi bấm vào item (tùy chọn)
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: PopupMenuButton<int>(
                        icon: const Icon(Icons.more_vert_outlined, color: Colors.white),
                        color: const Color(0xFF1E1E1E), // Màu nền của Popup Menu
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        position: PopupMenuPosition.under,

                        onSelected: (value) {
                          final controller = Get.find<LinkDetailController>();
                          if (value == 0) {
                            controller.openInApp();
                          } else if (value == 1) {
                            controller.goToEdit();
                          } else if (value == 2) {
                            controller.deleteLink();
                          }
                        },

                        // Đây là nơi bạn tự gắn Design UI của bạn vào (dùng PopupMenuItem)
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 0,
                            // Design Nút 1 của bạn để ở child này
                            child: Text('Open in App', style: TextStyle(color: Colors.white)),
                          ),
                          PopupMenuItem(
                            value: 1,
                            // Design Nút 2 của bạn để ở child này
                            child: Text('Edit Entry', style: TextStyle(color: Colors.white)),
                          ),
                          const PopupMenuDivider(), // Đường kẻ ngang (có thể xóa nếu không thích)
                          PopupMenuItem(
                            value: 2,
                            // Design Nút 3 của bạn để ở child này
                            child: Text('Remove from Library', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeroMediaWidget(),
                      const SizedBox(height: 16),
                      LinkTagsRow(),
                      const SizedBox(height: 16),
                      _TitleText(),
                      const SizedBox(height: 8),
                      _DescriptionText(),
                      const SizedBox(height: 18),
                      DestinationCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.grey.withOpacityCompat(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

class _TitleText extends GetView<LinkDetailController> {
  @override
  Widget build(BuildContext context) {
    if (controller.title.isEmpty) return const SizedBox.shrink();
    return TextWidget(
      text: controller.title,
      textStyle: AppTextStyle.bold22,
      color: Colors.white,
      maxLines: 3,
    );
  }
}

class _DescriptionText extends GetView<LinkDetailController> {
  @override
  Widget build(BuildContext context) {
    if (controller.description.isEmpty) return const SizedBox.shrink();
    return TextWidget(
      text: controller.description,
      textStyle: AppTextStyle.regular12,
      color: const Color(0xFFA0A0A0),
      maxLines: 5,
    );
  }
}
