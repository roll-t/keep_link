import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/friend/application/model/friend_request_model.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/page/shared_categories_page.dart';

Future<void> openRequestsSheet(
  BuildContext context,
  FriendController controller,
) async {
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
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 48,
                  color: AppColors.n500,
                ),
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
          final isProcessing = controller.processingRequestUserIds.contains(
            req.fromUserId,
          );
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
          SharedOwnerAvatar(
            displayName: request.displayName,
            photoUrl: request.photoUrl,
            size: 42,
          ),
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
            onPressed: isProcessing ? null : onDecline,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.white,
              side: BorderSide(color: AppColors.n500.withOpacityCompat(0.35)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 34),
            ),
            child: TextWidget(
              text: 'Decline'.tr,
              color: AppColors.white,
              size: 12,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isProcessing ? null : onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 34),
            ),
            child: isProcessing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : TextWidget(
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
