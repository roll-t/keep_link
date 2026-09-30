import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/image/cache_image.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/friend/application/model/friend_request_model.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';

Future<void> openRequestsSheet(BuildContext context, FriendController controller) async {
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
          Expanded(child: RequestsTabContent(controller: controller)),
        ],
      ),
    ),
  );
}

class RequestsTabContent extends StatelessWidget {
  const RequestsTabContent({super.key, required this.controller});

  final FriendController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final requests = controller.incomingRequests;
      if (requests.isEmpty) {
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
              ),
            ),
          ),
        );
      }

      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, index) {
          final req = requests[index];
          final isProcessing = controller.processingRequestUserIds.contains(req.fromUserId);
          return FriendRequestCard(
            request: req,
            isProcessing: isProcessing,
            onAccept: () async {
              await controller.acceptFriendRequest(req);
            },
            onDecline: () => controller.declineFriendRequest(req),
          );
        },
      );
    });
  }
}

class FriendRequestCard extends StatelessWidget {
  const FriendRequestCard({
    super.key,
    required this.request,
    required this.isProcessing,
    required this.onAccept,
    required this.onDecline,
  });

  final FriendRequestModel request;
  final bool isProcessing;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;

  static String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks tuần';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months tháng';
    } else {
      final years = (diff.inDays / 365).floor();
      return '$years năm';
    }
  }

  Widget _buildAvatar() {
    if (request.photoUrl != null && request.photoUrl!.trim().isNotEmpty) {
      return ClipOval(child: CacheImageWidget(imageUrl: request.photoUrl!, width: 66, height: 66));
    }

    return Container(
      width: 66,
      height: 66,
      decoration: const BoxDecoration(color: Color(0xFF3A3B3C), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: const Icon(Icons.person_rounded, size: 40, color: Color(0xFF8E8E93)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(request.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextWidget(
                        text: request.displayName,
                        textStyle: AppTextStyle.semiBold14,
                        maxLines: 1,
                      ),
                    ),
                    if (timeAgo.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      TextWidget(
                        text: timeAgo,
                        color: AppColors.white.withOpacityCompat(0.55),
                        textStyle: AppTextStyle.regular10,
                      ),
                    ],
                  ],
                ),
                if ((request.email ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: TextWidget(
                      text: request.email!,
                      color: AppColors.white.withOpacityCompat(0.55),
                      textStyle: AppTextStyle.regular10,
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Nút Xác nhận (Facebook Blue)
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: isProcessing ? null : onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1877F2),
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: isProcessing
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Text(
                                  'Xác nhận',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Nút Xóa (Facebook Secondary Grey)
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: isProcessing ? null : onDecline,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A3B3C),
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Xóa',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
