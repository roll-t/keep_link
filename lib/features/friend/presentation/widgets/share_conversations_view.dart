import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/friend/application/di/share_conversation_binding.dart';
import 'package:keep_link/features/friend/presentation/controller/share_conversations_controller.dart';
import 'package:keep_link/features/friend/presentation/page/share_conversation_page.dart';
import 'package:keep_link/features/friend/presentation/page/shared_categories_page.dart';
import 'package:keep_link/features/friend/presentation/widgets/shared_categories_tab.dart';

class ShareConversationsView extends GetView<ShareConversationsController> {
  const ShareConversationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.d500,
      onRefresh: controller.refreshConversations,
      child: Obx(() {
        final conversations = controller.conversations;

        if (controller.isInitialLoading.value) {
          return const SharedLoadingView();
        }
        if (controller.isLoading && conversations.isEmpty) {
          return const SharedLoadingView();
        }
        if (controller.errorMessage != null && conversations.isEmpty) {
          return SharedErrorView(
            message: controller.errorMessage!,
            onRetry: controller.refreshConversations,
          );
        }
        if (conversations.isEmpty) return const _EmptyConversations();

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 4, bottom: 32),
          itemCount: conversations.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 1,
            indent: 82,
            color: AppColors.white.withOpacityCompat(.06),
          ),
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _ConversationTile(
              data: conversation,
              onTap: () async {
                await Get.toNamed(
                  ShareConversationPage.routeName,
                  arguments: ShareConversationArguments(friend: conversation.friend),
                );
                await controller.reloadAfterConversation();
              },
            );
          },
        );
      }),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.data, required this.onTap});

  final ShareConversationSummary data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SharedOwnerAvatar(
                    displayName: data.friend.displayName,
                    photoUrl: data.friend.photoUrl,
                    size: 50,
                  ),
                  if (data.unreadItems > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AppColors.bg700, width: 2),
                        ),
                        child: TextWidget(
                          text: '${data.unreadItems}',
                          color: AppColors.white,
                          size: 9,
                          fontWeight: FontWeight.w700,
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
                    Row(
                      children: [
                        Expanded(
                          child: TextWidget(
                            text: data.friend.displayName,
                            color: AppColors.white,
                            size: 15,
                            fontWeight: data.unreadItems > 0 ? FontWeight.w700 : FontWeight.w600,
                            maxLines: 1,
                          ),
                        ),
                        if (data.latestAt != null)
                          TextWidget(
                            text: _compactTime(data.latestAt!),
                            color: AppColors.n500,
                            size: 11,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: TextWidget(
                            text: data.preview,
                            color: data.unreadItems > 0 ? AppColors.t200 : AppColors.n70,
                            size: 12.5,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextWidget(text: '${data.totalItems}', color: AppColors.n500, size: 11),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _compactTime(DateTime time) {
    final now = DateTime.now();
    if (now.year == time.year && now.month == time.month && now.day == time.day) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}';
  }
}

class _EmptyConversations extends StatelessWidget {
  const _EmptyConversations();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(color: AppColors.d500, shape: BoxShape.circle),
                    child: const Icon(Icons.forum_outlined, color: AppColors.primary, size: 38),
                  ),
                  const SizedBox(height: 18),
                  const TextWidget(
                    text: 'Chưa có trao đổi link',
                    color: AppColors.white,
                    size: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 7),
                  const TextWidget(
                    text:
                        'Khi bạn và bạn bè chia sẻ link hoặc danh mục, cuộc trò chuyện sẽ xuất hiện tại đây.',
                    color: AppColors.n70,
                    size: 12,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
