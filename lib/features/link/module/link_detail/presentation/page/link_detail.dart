import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/controller/link_detail_controller.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/category_card.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/destination_card.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/download_video_card.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/hero_media_widget.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/widgets/link_detail_app_bar.dart';

class LinkDetailPage extends GetView<LinkDetailController> {
  static const routeName = '/LinkDetailPage';
  final LinkModel? link;
  final bool readOnly;
  const LinkDetailPage({super.key, this.link, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Obx(() {
        final isFullscreenPlayer = controller.isPlayingVideo.value && controller.isExpanded.value;

        if (isFullscreenPlayer) {
          return const Scaffold(
            backgroundColor: AppColors.surfaceDeep,
            body: SafeArea(top: true, bottom: false, child: HeroMediaWidget()),
          );
        }

        final dragOffset = controller.dragOffsetY.value;
        final bgOpacity = (1.0 - (dragOffset / 600)).clamp(0.4, 1.0);

        return AnimatedContainer(
          duration: controller.isDragging.value ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, dragOffset, 0),
          child: Scaffold(
            backgroundColor: AppColors.surfaceDeep.withOpacityCompat(bgOpacity),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragStart: (_) => controller.onVerticalDragStart(),
                onVerticalDragUpdate: (details) =>
                    controller.onVerticalDragUpdate(details.delta.dy),
                onVerticalDragEnd: (details) =>
                    controller.onVerticalDragEnd(details.primaryVelocity ?? 0.0),
                child: const LinkDetailAppBar(),
              ),
            ),
            body: const _BodyBuilder(),
          ),
        );
      }),
    );
  }
}

class _BodyBuilder extends GetView<LinkDetailController> {
  const _BodyBuilder();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: (_) => controller.onVerticalDragStart(),
          onVerticalDragUpdate: (details) => controller.onVerticalDragUpdate(details.delta.dy),
          onVerticalDragEnd: (details) =>
              controller.onVerticalDragEnd(details.primaryVelocity ?? 0.0),
          child: const HeroMediaWidget(),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                final delta = notification.scrollDelta ?? 0.0;
                if (notification.metrics.pixels <= 0) {
                  if (delta < 0 || controller.dragOffsetY.value > 0) {
                    controller.onVerticalDragUpdate(-delta);
                  }
                }
              } else if (notification is OverscrollNotification) {
                if (notification.overscroll < 0) {
                  controller.onVerticalDragUpdate(-notification.overscroll);
                }
              } else if (notification is ScrollEndNotification) {
                final velocity = notification.dragDetails?.primaryVelocity ?? 0.0;
                controller.onVerticalDragEnd(velocity);
              }
              return false;
            },
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  if (controller.title.isNotEmpty)
                    TextWidget(
                      text: controller.title,
                      textStyle: AppTextStyle.bold20,
                      color: AppColors.white,
                      maxLines: 2,
                    ),
                  if (controller.description.isNotEmpty) ...[
                    TextWidget(
                      text: controller.description,
                      textStyle: AppTextStyle.regular12,
                      color: AppColors.mediaTextMuted,
                      maxLines: 2,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Column(
                    spacing: 8,
                    children: [
                      const DestinationCard(),
                      if (controller.isMine) const CategoryCard(),
                      const DownloadVideoCard(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
