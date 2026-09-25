import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/animation/app_entrance_animation.dart';
import 'package:keep_link/core/presentation/widgets/background/app_animated_background.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/link_collection_controller.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/widgets/bottom_bar.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/widgets/header_link_collection.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/widgets/list_link_collection.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/widgets/selection_action_bar.dart';

class LinkCollectionPage extends GetView<LinkCollectionController> {
  static const String routeName = "/LinkCollectionPage";

  const LinkCollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: !controller.isSelectionMode.value,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && controller.isSelectionMode.value) {
            controller.exitSelectionMode();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: const _BodyBuilder(),
          extendBody: true,
          floatingActionButton: AppEntranceAnimation(
            delay: const Duration(milliseconds: 220),
            beginOffset: const Offset(0, .22),
            child: controller.isSelectionMode.value
                ? const SelectionActionBar()
                : const GlassBottomBar(),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        ),
      ),
    );
  }
}

class _BodyBuilder extends StatelessWidget {
  const _BodyBuilder();
  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    return SafeArea(
      top: false,
      child: Stack(
        children: [
          const Positioned.fill(child: AppAnimatedBackground(intensity: .82)),
          const AppEntranceAnimation(
            delay: Duration(milliseconds: 70),
            beginOffset: Offset(0, .035),
            child: ListLinkCollection(),
          ),
          IgnorePointer(
            child: Container(
              width: double.infinity,
              height: safeTop + 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.black.withOpacityCompat(.8),
                    AppColors.black.withOpacityCompat(.5),
                    AppColors.black.withOpacityCompat(.2),
                    AppColors.transparent,
                    AppColors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                width: double.infinity,
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.black.withOpacityCompat(.4),
                      AppColors.black.withOpacityCompat(.2),
                      AppColors.black.withOpacityCompat(.1),
                      AppColors.transparent,
                      AppColors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppEntranceAnimation(
              delay: Duration(milliseconds: 130),
              beginOffset: Offset(0, -.16),
              child: HeaderLinkCollection(),
            ),
          ),
        ],
      ),
    );
  }
}
