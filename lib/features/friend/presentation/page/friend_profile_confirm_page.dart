import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/image/cache_image.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/services/backend/friend_connection_service.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';

class FriendProfileConfirmPage extends StatefulWidget {
  static const routeName = '/FriendProfileConfirmPage';

  final FriendConnectionPayload payload;
  final FriendController controller;

  const FriendProfileConfirmPage({
    super.key,
    required this.payload,
    required this.controller,
  });

  @override
  State<FriendProfileConfirmPage> createState() =>
      _FriendProfileConfirmPageState();
}

class _FriendProfileConfirmPageState extends State<FriendProfileConfirmPage> {
  bool _isSubmitting = false;

  Future<void> _sendFriendRequest() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final success = await widget.controller.addFriendFromLink(
        widget.payload.rawLink,
      );
      if (!mounted) return;
      if (success) {
        Get.back(result: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.payload;
    final hasPhoto = payload.photoUrl != null && payload.photoUrl!.isNotEmpty;
    final initial = payload.displayName.isNotEmpty
        ? payload.displayName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.d500,
      appBar: AppBar(
        backgroundColor: AppColors.d500,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.white,
            size: 20,
          ),
          onPressed: () => Get.back(result: false),
        ),
        title: TextWidget(
          text: 'Add Friend'.tr,
          color: AppColors.white,
          size: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Avatar & Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.d300,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.white.withOpacityCompat(0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacityCompat(0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar with ring effect
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacityCompat(0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: hasPhoto
                                ? CacheImageWidget(
                                    imageUrl: payload.photoUrl!,
                                    width: 90,
                                    height: 90,
                                    borderRadius: BorderRadius.circular(45),
                                  )
                                : Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: AppColors.navigationSurface,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: TextWidget(
                                      text: initial,
                                      color: AppColors.primary,
                                      size: 36,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 18),

                          // Display Name
                          TextWidget(
                            text: payload.displayName.isNotEmpty
                                ? payload.displayName
                                : 'Unnamed User',
                            color: AppColors.white,
                            size: 20,
                            fontWeight: FontWeight.w700,
                            textAlign: TextAlign.center,
                          ),

                          // Email
                          if (payload.email != null &&
                              payload.email!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.mail_outline_rounded,
                                  color: AppColors.n70,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: TextWidget(
                                    text: payload.email!,
                                    color: AppColors.n70,
                                    size: 14,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 18),

                          // Tag "Scanned via QR Code"
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacityCompat(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withOpacityCompat(
                                  0.24,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: AppColors.primary,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                TextWidget(
                                  text: 'Quét từ mã QR',
                                  color: AppColors.primary,
                                  size: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Feature Highlight Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.d300.withOpacityCompat(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.white.withOpacityCompat(0.06),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureRow(
                            icon: Icons.folder_shared_outlined,
                            title: 'Chia sẻ bộ sưu tập liên kết',
                            subtitle:
                                'Dễ dàng gửi và đồng bộ các danh mục link hữu ích cùng bạn bè.',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              color: AppColors.white.withOpacityCompat(0.06),
                              height: 1,
                            ),
                          ),
                          _buildFeatureRow(
                            icon: Icons.sync_rounded,
                            title: 'Cập nhật theo thời gian thực',
                            subtitle:
                                'Mọi thay đổi trong danh mục được chia sẻ sẽ luôn đồng bộ tức thì.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.d500,
                border: Border(
                  top: BorderSide(
                    color: AppColors.white.withOpacityCompat(0.06),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Cancel button
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Get.back(result: false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.white.withOpacityCompat(0.2),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: TextWidget(
                          text: 'cancel'.tr,
                          color: AppColors.white,
                          size: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Send Request button
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _sendFriendRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          disabledBackgroundColor: AppColors.primary
                              .withOpacityCompat(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.person_add_rounded,
                                    color: AppColors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  TextWidget(
                                    text: 'Send Request'.tr,
                                    color: AppColors.white,
                                    size: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacityCompat(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
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
              const SizedBox(height: 3),
              TextWidget(
                text: subtitle,
                color: AppColors.n70,
                size: 12.5,
                height: 1.3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
