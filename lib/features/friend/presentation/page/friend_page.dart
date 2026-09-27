import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';
import 'package:keep_link/features/friend/presentation/page/qr_scanner_page.dart';
import 'package:keep_link/features/friend/presentation/widgets/add_friend_sheets.dart';
import 'package:keep_link/features/friend/presentation/widgets/friend_requests_sheet.dart';
import 'package:keep_link/features/friend/presentation/widgets/friends_manage_tab.dart';
import 'package:keep_link/features/friend/presentation/widgets/share_conversations_view.dart';

class FriendPage extends StatefulWidget {
  static const routeName = '/FriendPage';

  const FriendPage({super.key});

  @override
  State<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  late final FriendController controller;
  late final SharedCategoryController sharedController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<FriendController>();
    sharedController = Get.find<SharedCategoryController>();
    controller.setFriendPageActive(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FriendController.markSharedCategoriesAsSeen();
      sharedController.loadAllSharedData();
    });
  }

  @override
  void dispose() {
    controller.setFriendPageActive(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          controller.setFriendPageActive(false);
        }
      },
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
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.t200, size: 20),
              onPressed: () {
                controller.setFriendPageActive(false);
                Get.back();
              },
            ),
            title: const TextWidget(
              text: 'Trao đổi link',
              color: AppColors.white,
              size: 18,
              fontWeight: FontWeight.w700,
            ),
            actions: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Scan QR'.tr,
                icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.n70, size: 22),
                onPressed: () => Get.to(() => QrScannerPage(controller: controller)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Add Friend'.tr,
                icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.n70, size: 22),
                onPressed: () => openAddFriendMethodsSheet(context, controller),
              ),
              Obx(() {
                final requestCount = controller.incomingRequests.length;
                return IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  tooltip: 'Friends'.tr,
                  onPressed: () => _openFriendsManager(context),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.people_alt_rounded, color: AppColors.n70, size: 23),
                      if (requestCount > 0)
                        Positioned(
                          right: -5,
                          top: -5,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 16),
                            height: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextWidget(
                              text: '$requestCount',
                              color: AppColors.white,
                              size: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(width: 8),
            ],
          ),
          body: ShareConversationsView(
            friendController: controller,
            sharedController: sharedController,
          ),
        ),
      ),
    );
  }

  Future<void> _openFriendsManager(BuildContext context, {int initialIndex = 0}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.modalSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) =>
          _FriendsManagerSheet(controller: controller, initialIndex: initialIndex),
    );
  }
}

class _FriendsManagerSheet extends StatefulWidget {
  const _FriendsManagerSheet({required this.controller, this.initialIndex = 0});

  final FriendController controller;
  final int initialIndex;

  @override
  State<_FriendsManagerSheet> createState() => _FriendsManagerSheetState();
}

class _FriendsManagerSheetState extends State<_FriendsManagerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .84,
        child: Column(
          children: [
            // Top drag handle
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacityCompat(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),

            // Tab bar header row with Close button
            Padding(
              padding: const EdgeInsets.only(left: 6, right: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: false,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      labelColor: AppColors.white,
                      unselectedLabelColor: AppColors.n70,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: [
                        Tab(
                          child: Obx(() {
                            final total = widget.controller.totalFriends;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Friends'.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (total > 0) ...[
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withOpacityCompat(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$total',
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          }),
                        ),
                        Tab(
                          child: Obx(() {
                            final reqCount = widget.controller.incomingRequests.length;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Friend Requests'.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (reqCount > 0) ...[
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
                                    child: Text(
                                      '$reqCount',
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.n70, size: 22),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  FriendsManageTab(
                    controller: widget.controller,
                    onRefresh: widget.controller.fetchFriends,
                    showRequestsTile: false,
                  ),
                  RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.d500,
                    onRefresh: widget.controller.fetchFriends,
                    child: RequestsTabContent(controller: widget.controller),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
