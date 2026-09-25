import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';
import 'package:keep_link/features/friend/presentation/page/qr_scanner_page.dart';
import 'package:keep_link/features/friend/presentation/widgets/add_friend_sheets.dart';
import 'package:keep_link/features/friend/presentation/widgets/friend_requests_sheet.dart';
import 'package:keep_link/features/friend/presentation/widgets/friends_manage_tab.dart';
import 'package:keep_link/features/friend/presentation/widgets/shared_categories_tab.dart';

class FriendPage extends GetView<FriendController> {
  static const routeName = '/FriendPage';

  const FriendPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sharedController = Get.find<SharedCategoryController>();
    controller.setFriendPageActive(true);
    FriendController.markSharedCategoriesAsSeen();
    sharedController.loadAllSharedData();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          controller.setFriendPageActive(false);
        }
      },
      child: DefaultTabController(
        length: 2,
        child: SafeArea(
          top: false,
          child: Scaffold(
            backgroundColor: AppColors.bg700,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: AppColors.bg700,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.t200,
                  size: 20,
                ),
                onPressed: () {
                  controller.setFriendPageActive(false);
                  Get.back();
                },
              ),
              title: TextWidget(
                text: 'Friends & Shared'.tr,
                color: AppColors.white,
                size: 18,
                fontWeight: FontWeight.w700,
              ),
              actions: [
                IconButton(
                  tooltip: 'Scan QR'.tr,
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.n70,
                    size: 22,
                  ),
                  onPressed: () =>
                      Get.to(() => QrScannerPage(controller: controller)),
                ),
                IconButton(
                  tooltip: 'Add Friend'.tr,
                  icon: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: AppColors.n70,
                    size: 22,
                  ),
                  onPressed: () =>
                      openAddFriendMethodsSheet(context, controller),
                ),
                const SizedBox(width: 4),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: SizedBox(
                  height: 52,
                  child: Obx(() {
                    final sharedCount =
                        sharedController.sharedCategories.length +
                        sharedController.sharedIndividualLinks.length;
                    final requestCount = controller.incomingRequests.length;

                    return TabBar(
                      dividerColor: AppColors.white.withOpacityCompat(.06),
                      dividerHeight: 1,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 1,
                      indicatorPadding: EdgeInsets.zero,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.n70,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Builder(
                                builder: (context) =>
                                    AppVectors.icShareLink.show(
                                      size: 18,
                                      color: IconTheme.of(context).color,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: TextWidget(
                                  text: 'Shared'.tr,
                                  maxLines: 1,
                                  textStyle: AppTextStyle.semiBold14,
                                ),
                              ),
                              if (sharedCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacityCompat(
                                      0.18,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withOpacityCompat(0.35),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: TextWidget(
                                    text: '$sharedCount',
                                    color: AppColors.primary,
                                    textStyle: AppTextStyle.regular10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_alt_rounded, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: TextWidget(
                                  text: 'Friends'.tr,
                                  maxLines: 1,
                                  textStyle: AppTextStyle.semiBold14,
                                ),
                              ),
                              if (requestCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: TextWidget(
                                    text: '$requestCount',
                                    color: AppColors.white,
                                    textStyle: AppTextStyle.regular10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            body: TabBarView(
              children: [
                SharedCategoriesTab(
                  controller: sharedController,
                  onRefresh: () =>
                      sharedController.loadSharedCategories(force: true),
                ),
                FriendsManageTab(
                  controller: controller,
                  onRefresh: controller.fetchFriends,
                  onOpenRequests: () => openRequestsSheet(context, controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
