import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/services/backend/friend_connection_service.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/application/model/friend_request_model.dart';
import 'package:keep_link/features/friend/application/model/shared_category_model.dart';
import 'package:keep_link/features/friend/application/model/shared_individual_link_model.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/controller/shared_category_controller.dart';
import 'package:keep_link/features/friend/presentation/page/qr_scanner_page.dart';
import 'package:keep_link/features/friend/presentation/page/shared_categories_page.dart';
import 'package:keep_link/features/link/module/link_detail/presentation/page/link_detail.dart';

class FriendPage extends StatefulWidget {
  static const routeName = '/FriendPage';

  const FriendPage({super.key});

  @override
  State<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> with SingleTickerProviderStateMixin {
  late final FriendController controller;
  late final SharedCategoryController sharedController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // FriendController/SharedCategoryController are persistent (bound from
    // LinkCollectionPage, see FriendBinding) and stay synced in the
    // background via Firebase realtime watchers for the whole session — so
    // opening this page just reads whatever state is already there, no
    // forced re-fetch. Pull-to-refresh below is the explicit manual escape
    // hatch if the user wants to force a resync.
    controller = Get.find<FriendController>();
    sharedController = Get.find<SharedCategoryController>();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            onPressed: () => Get.back(),
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
              icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.n70, size: 22),
              onPressed: () => _openQrScanner(context),
            ),
            IconButton(
              tooltip: 'Add Friend'.tr,
              icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.n70, size: 22),
              onPressed: () => _openAddFriendMethodsSheet(context),
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.white.withOpacityCompat(0.08), width: 1),
                ),
              ),
              child: Obx(() {
                final sharedCount =
                    sharedController.sharedCategories.length +
                    sharedController.sharedIndividualLinks.length;
                final requestCount = controller.incomingRequests.length;

                return TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(color: AppColors.primary, width: 3.0),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.n70,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  tabs: [
                    // Tab 1: Được chia sẻ
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder_shared_rounded, size: 18),
                          const SizedBox(width: 8),
                          Flexible(child: Text('Shared'.tr, overflow: TextOverflow.ellipsis)),
                          if (sharedCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacityCompat(0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primary.withOpacityCompat(0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '$sharedCount',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Tab 2: Bạn bè
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_alt_rounded, size: 18),
                          const SizedBox(width: 8),
                          Flexible(child: Text('Friends'.tr, overflow: TextOverflow.ellipsis)),
                          if (requestCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$requestCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
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
        body: Obx(() {
          if (controller.isLoading.value || sharedController.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // ── Tab 1: Danh mục được chia sẻ ──────────────────────────────
              _SharedCategoriesTab(
                controller: sharedController,
                onRefresh: () => Future.wait([
                  controller.fetchFriends(),
                  sharedController.loadSharedCategories(),
                ]),
              ),

              // ── Tab 2: Quản lý bạn bè & Lời mời ───────────────────────────
              _FriendsManageTab(
                controller: controller,
                onRefresh: () => Future.wait([
                  controller.fetchFriends(),
                  sharedController.loadSharedCategories(),
                ]),
                onOpenRequests: () => _openRequestsSheet(context),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Bottom Sheets ──────────────────────────────────────────────────────────

  Future<void> _openRequestsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg700,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.n500,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            TextWidget(
              text: 'Friend Requests'.tr,
              color: AppColors.white,
              size: 18,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 8),
            Expanded(child: _RequestsTabContent(controller: controller)),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddFriendMethodsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.d500,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddFriendMethodsSheet(
        onAddByGmail: () => _openAddByGmailSheet(context),
        onAddByLink: () => _openAddByLinkSheet(context),
      ),
    );
  }

  Future<void> _openAddByLinkSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.d500,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddFriendByLinkSheet(controller: controller),
    );
  }

  Future<void> _openAddByGmailSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.d500,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddFriendByGmailSheet(controller: controller),
    );
  }

  void _openQrScanner(BuildContext context) {
    Get.to(() => QrScannerPage(controller: controller));
  }
}

// ── Tab 1: Shared Categories + Individual Links View ─────────────────────────

class _SharedCategoriesTab extends StatelessWidget {
  const _SharedCategoriesTab({required this.controller, required this.onRefresh});

  final SharedCategoryController controller;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.d500,
      onRefresh: onRefresh,
      child: Obx(() {
        // Danh mục và link lẻ được chia sẻ dùng 2 node Firebase khác nhau
        // (xem shareCategory/shareLink trong FirebaseService) nên phải gộp
        // lại thành 1 danh sách ở đây — trước đây tab này chỉ đọc
        // sharedCategories, nên link chia sẻ đơn lẻ (không qua danh mục)
        // không bao giờ hiện ra dù đã share thành công.
        final items = <Object>[...controller.sharedCategories, ...controller.sharedIndividualLinks]
          ..sort((a, b) {
            final ta =
                (a is SharedCategoryModel
                    ? a.sharedAt
                    : (a as SharedIndividualLinkModel).sharedAt) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final tb =
                (b is SharedCategoryModel
                    ? b.sharedAt
                    : (b as SharedIndividualLinkModel).sharedAt) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return tb.compareTo(ta);
          });

        if (items.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: const _EmptySharedView(),
              ),
            ),
          );
        }

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 4, bottom: 32),
          itemCount: items.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, thickness: 0.8, color: AppColors.white.withOpacityCompat(0.12)),
          itemBuilder: (ctx, index) {
            final item = items[index];

            if (item is SharedCategoryModel) {
              final key = '${item.ownerUid}/${item.categoryId}';
              return Obx(() {
                final isUnviewed = controller.unviewedKeys.contains(key);
                return _SharedCategoryCard(
                  category: item,
                  isUnviewed: isUnviewed,
                  onTap: () => openSharedCategoryLinksSheet(context, controller, item),
                );
              });
            }

            final linkItem = item as SharedIndividualLinkModel;
            final key = '${linkItem.ownerUid}/${linkItem.linkId}';
            return Obx(() {
              final isUnviewed = controller.unviewedKeys.contains(key);
              return _SharedLinkCard(
                item: linkItem,
                isUnviewed: isUnviewed,
                onTap: () {
                  controller.markLinkViewed(linkItem);
                  Get.toNamed(LinkDetailPage.routeName, arguments: linkItem.link);
                },
              );
            });
          },
        );
      }),
    );
  }
}

// ── Tab 2: Friends Management View ───────────────────────────────────────────

class _FriendsManageTab extends StatelessWidget {
  const _FriendsManageTab({
    required this.controller,
    required this.onRefresh,
    required this.onOpenRequests,
  });

  final FriendController controller;
  final RefreshCallback onRefresh;
  final VoidCallback onOpenRequests;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.d500,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ── Quick Action Card (Friend Requests) ─────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.d500,
              border: Border(
                bottom: BorderSide(color: AppColors.white.withOpacityCompat(0.12), width: 0.8),
              ),
            ),
            child: Obx(() {
              final reqCount = controller.incomingRequests.length;
              return _ZaloTile(
                icon: Icons.group_add_rounded,
                iconColor: Colors.white,
                iconBgColor: const Color(0xFF0068FF),
                title: 'Friend Requests'.tr,
                subtitle: reqCount > 0 ? '$reqCount ${'requests_pending'.tr}' : null,
                badgeCount: reqCount,
                onTap: onOpenRequests,
              );
            }),
          ),
          // ── Section Title: Friends List ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Obx(
              () => TextWidget(
                text: '${'Friends'.tr} (${controller.totalFriends}/${FriendController.maxFriends})',
                color: AppColors.white,
                size: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // ── Friends List Items ───────────────────────────────────────────
          Obx(() {
            final friends = controller.visibleFriends;
            if (friends.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.n500),
                      const SizedBox(height: 12),
                      TextWidget(text: 'No friends found'.tr, color: AppColors.n70, size: 14),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: friends.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 0.8,
                color: AppColors.white.withOpacityCompat(0.12),
              ),
              itemBuilder: (_, index) {
                final friend = friends[index];
                return _FriendItem(
                  friend: friend,
                  onDelete: () => controller.confirmDeleteFriend(friend),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

// ── Quick Tile Widget ────────────────────────────────────────────────────────

class _ZaloTile extends StatelessWidget {
  const _ZaloTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    this.subtitle,
    this.badgeCount = 0,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String? subtitle;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: title,
                      color: AppColors.white,
                      size: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      TextWidget(text: subtitle!, color: AppColors.n70, size: 12),
                    ],
                  ],
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextWidget(
                    text: '$badgeCount',
                    color: Colors.white,
                    size: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.n500, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared Category Card ─────────────────────────────────────────────────────

class _SharedCategoryCard extends StatelessWidget {
  const _SharedCategoryCard({required this.category, required this.onTap, this.isUnviewed = false});

  final SharedCategoryModel category;
  final VoidCallback onTap;
  final bool isUnviewed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SharedOwnerAvatar(
                    displayName: category.ownerDisplayName,
                    photoUrl: category.ownerPhotoUrl,
                    size: 46,
                  ),
                  if (isUnviewed)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bg700, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: category.categoryName,
                      color: AppColors.white,
                      size: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 13, color: AppColors.n70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextWidget(
                            text: category.ownerDisplayName,
                            color: AppColors.n70,
                            size: 13,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    if (category.categoryDescription != null &&
                        category.categoryDescription!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      TextWidget(
                        text: category.categoryDescription!,
                        color: AppColors.n500,
                        size: 12,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacityCompat(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    TextWidget(
                      text: '${category.linkCount}',
                      color: AppColors.primary,
                      size: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.n500),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared Individual Link Card ───────────────────────────────────────────────

class _SharedLinkCard extends StatelessWidget {
  const _SharedLinkCard({required this.item, required this.onTap, this.isUnviewed = false});

  final SharedIndividualLinkModel item;
  final VoidCallback onTap;
  final bool isUnviewed;

  @override
  Widget build(BuildContext context) {
    final title = item.link.name ?? item.link.metaDataModel?.title ?? 'Link'.tr;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SharedOwnerAvatar(
                    displayName: item.ownerDisplayName,
                    photoUrl: item.ownerPhotoUrl,
                    size: 46,
                  ),
                  if (isUnviewed)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bg700, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: title,
                      color: AppColors.white,
                      size: 15,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 13, color: AppColors.n70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextWidget(
                            text: item.ownerDisplayName,
                            color: AppColors.n70,
                            size: 13,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacityCompat(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.link_rounded, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.n500),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptySharedView extends StatelessWidget {
  const _EmptySharedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.d500,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white.withOpacityCompat(0.08)),
              ),
              child: const Center(
                child: Icon(Icons.folder_shared_rounded, size: 38, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: 'no_shared_categories'.tr,
              color: AppColors.white,
              size: 16,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            TextWidget(
              text: 'no_shared_categories_desc'.tr,
              color: AppColors.n70,
              size: 12,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Friend Item Card ─────────────────────────────────────────────────────────

class _FriendItem extends StatelessWidget {
  const _FriendItem({required this.friend, required this.onDelete});

  final FriendModel friend;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SharedOwnerAvatar(displayName: friend.displayName, photoUrl: friend.photoUrl, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: friend.displayName,
                    color: AppColors.white,
                    size: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  if ((friend.email ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: TextWidget(
                        text: friend.email!,
                        color: AppColors.n70,
                        size: 13,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Requests Tab Content (in bottom sheet) ───────────────────────────────────

class _RequestsTabContent extends StatelessWidget {
  const _RequestsTabContent({required this.controller});

  final FriendController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final requests = controller.incomingRequests;
      if (requests.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.n500),
                const SizedBox(height: 12),
                TextWidget(
                  text: 'No pending requests'.tr,
                  color: AppColors.n70,
                  size: 14,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        itemCount: requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final req = requests[index];
          return _FriendRequestCard(
            request: req,
            onAccept: () => controller.acceptFriendRequest(req),
            onDecline: () => controller.declineFriendRequest(req),
          );
        },
      );
    });
  }
}

class _FriendRequestCard extends StatelessWidget {
  const _FriendRequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  final FriendRequestModel request;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.d500,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white.withOpacityCompat(0.06)),
      ),
      child: Row(
        children: [
          SharedOwnerAvatar(displayName: request.displayName, photoUrl: request.photoUrl, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: request.displayName,
                  color: AppColors.white,
                  size: 14,
                  fontWeight: FontWeight.w600,
                ),
                if ((request.email ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: TextWidget(
                      text: request.email!,
                      color: AppColors.n70,
                      size: 12,
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onDecline,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.white,
              side: BorderSide(color: AppColors.n500.withOpacityCompat(0.35)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 34),
            ),
            child: TextWidget(text: 'Decline'.tr, color: AppColors.white, size: 12),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 34),
            ),
            child: TextWidget(
              text: 'Accept'.tr,
              color: AppColors.white,
              size: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Friend Methods BottomSheet ───────────────────────────────────────────

class _AddFriendMethodsSheet extends StatelessWidget {
  const _AddFriendMethodsSheet({required this.onAddByGmail, required this.onAddByLink});

  final VoidCallback onAddByGmail;
  final VoidCallback onAddByLink;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.n500,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: 'Choose Add Friend Method'.tr,
              color: AppColors.white,
              size: 18,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 6),
            TextWidget(
              text: 'You can add friends by Gmail or personal link.'.tr,
              color: AppColors.n70,
              size: 13,
            ),
            const SizedBox(height: 16),
            _MethodTile(
              icon: Icons.alternate_email_rounded,
              title: 'Add via Gmail'.tr,
              subtitle: 'Find a friend account with their Gmail.'.tr,
              onTap: () {
                Navigator.of(context).pop();
                onAddByGmail();
              },
            ),
            const SizedBox(height: 10),
            _MethodTile(
              icon: Icons.link_rounded,
              title: 'Add via Link'.tr,
              subtitle: 'Paste your friend\'s personal link.'.tr,
              onTap: () {
                Navigator.of(context).pop();
                onAddByLink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg700,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacityCompat(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: title,
                      color: AppColors.white,
                      size: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 2),
                    TextWidget(text: subtitle, color: AppColors.n70, size: 12),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.n500, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add via Gmail Sheet ──────────────────────────────────────────────────────

class _AddFriendByGmailSheet extends StatefulWidget {
  const _AddFriendByGmailSheet({required this.controller});

  final FriendController controller;

  @override
  State<_AddFriendByGmailSheet> createState() => _AddFriendByGmailSheetState();
}

class _AddFriendByGmailSheetState extends State<_AddFriendByGmailSheet> {
  final _emailCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      AppToast.showToast('Please enter an email'.tr, Icons.warning_rounded, color: Colors.orange);
      return;
    }
    setState(() => _submitting = true);
    final success = await widget.controller.addFriendFromEmail(email);
    setState(() => _submitting = false);
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.n500,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: 'Add via Gmail'.tr,
              color: AppColors.white,
              size: 18,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 6),
            TextWidget(
              text: 'Find a friend account with their Gmail.'.tr,
              color: AppColors.n70,
              size: 13,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'name@gmail.com',
                hintStyle: const TextStyle(color: AppColors.n500),
                filled: true,
                fillColor: AppColors.bg700,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : TextWidget(
                        text: 'Send Request'.tr,
                        color: Colors.white,
                        size: 14,
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add via Link Sheet ───────────────────────────────────────────────────────

class _AddFriendByLinkSheet extends StatefulWidget {
  const _AddFriendByLinkSheet({required this.controller});

  final FriendController controller;

  @override
  State<_AddFriendByLinkSheet> createState() => _AddFriendByLinkSheetState();
}

class _AddFriendByLinkSheetState extends State<_AddFriendByLinkSheet> {
  final _linkCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      _linkCtrl.text = text;
    }
  }

  Future<void> _submit() async {
    final raw = _linkCtrl.text.trim();
    if (raw.isEmpty) {
      AppToast.showToast(
        'Please enter a friend link'.tr,
        Icons.warning_rounded,
        color: Colors.orange,
      );
      return;
    }

    // Parse trước để có thể hiện tên/ảnh cho user xác nhận trước khi thực sự
    // gửi lời mời — payload này do link tự khai, không được xác thực bởi
    // Firebase nên không nên gửi ngay lập tức mà không cho user xem qua.
    final payload = FriendConnectionService.parseLink(raw);
    if (payload == null) {
      AppToast.showToast('friend_invalid_link'.tr, Icons.error_outline_rounded, color: Colors.red);
      return;
    }

    final confirmed = await showFriendRequestConfirmSheet(context, payload);
    if (!confirmed || !mounted) return;

    setState(() => _submitting = true);
    final success = await widget.controller.addFriendFromLink(raw);
    setState(() => _submitting = false);
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.n500,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: 'Add via Link'.tr,
              color: AppColors.white,
              size: 18,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 6),
            TextWidget(
              text: 'Paste your friend\'s personal link.'.tr,
              color: AppColors.n70,
              size: 13,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _linkCtrl,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'keeplink://open/friend?data=...',
                hintStyle: const TextStyle(color: AppColors.n500),
                filled: true,
                fillColor: AppColors.bg700,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste_rounded, color: AppColors.primary),
                  onPressed: _pasteFromClipboard,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : TextWidget(
                        text: 'Send Request'.tr,
                        color: Colors.white,
                        size: 14,
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
