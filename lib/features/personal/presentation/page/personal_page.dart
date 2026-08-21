import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:keep_link/core/presentation/widgets/image/cache_image.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/features/friend/presentation/page/my_qr_page.dart';
import 'package:keep_link/features/personal/presentation/controller/personal_controller.dart';
import 'package:keep_link/features/personal/presentation/page/settings_page.dart';

class PersonalPage extends GetView<PersonalController> {
  static const routeName = '/PersonalPage';

  const PersonalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.bg700,
        appBar: CustomAppBar(
          title: "Personal".tr,
          centerTitle: false,
          titleStyle: AppTextStyle.bold20,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.n70, size: 22),
              tooltip: 'Settings'.tr,
              onPressed: () => Get.toNamed(SettingsPage.routeName),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Obx(() {
          final currentUser = controller.user.value;
          final isLoggedIn = currentUser != null;
          AppCache.links.length;
          AppCache.categories.length;
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Profile card (Edge-to-edge) ─────────────────────────────
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.d500,
                    border: Border(
                      bottom: BorderSide(color: AppColors.white.withOpacityCompat(0.06), width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // ── Avatar ──────────────────────────────────────────
                      Obx(() {
                        final uploading = controller.isUploadingAvatar.value;
                        return GestureDetector(
                          onTap: isLoggedIn && !uploading
                              ? () => _showAvatarBottomSheet(context, currentUser)
                              : null,
                          child: Stack(
                            children: [
                              CacheImageWidget(
                                imageUrl: isLoggedIn && (currentUser.photoURL?.isNotEmpty == true)
                                    ? currentUser.photoURL!
                                    : '',
                                width: 76,
                                height: 76,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(38),
                                errorWidget: Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacityCompat(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person, size: 38, color: AppColors.white),
                                ),
                              ),
                              if (uploading)
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacityCompat(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              if (isLoggedIn && !uploading)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.d500, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      size: 13,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextWidget(
                            text: isLoggedIn
                                ? (currentUser.displayName?.isNotEmpty == true
                                      ? currentUser.displayName!
                                      : 'No display name'.tr)
                                : 'Guest User'.tr,
                            color: AppColors.white,
                            size: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          if (isLoggedIn) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: controller.showEditNameDialog,
                              child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.n60),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextWidget(
                        text: isLoggedIn
                            ? (currentUser.email ?? 'No email'.tr)
                            : 'Not signed in'.tr,
                        color: AppColors.n70,
                        size: 13.5,
                      ),
                    ],
                  ),
                ),

                // ── Guest Sign In Button ───────────────────────────────────
                if (!isLoggedIn) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: controller.isLoading.value ? null : controller.signInWithGoogle,
                      icon: controller.isLoading.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.login_rounded, size: 20, color: Colors.white),
                      label: TextWidget(
                        text: controller.isLoading.value
                            ? 'Please wait...'.tr
                            : 'Sign In with Google'.tr,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        size: 15,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
                // ── Stats (Flush Grid) ─────────────────────────────────────
                if (isLoggedIn) ...[
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.d500,
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: AppColors.white.withOpacityCompat(0.06),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCell(
                            icon: Icons.link_rounded,
                            value: '${controller.totalLinks}',
                            label: 'Total Links'.tr,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          width: 0.5,
                          height: 60,
                          color: AppColors.white.withOpacityCompat(0.08),
                        ),
                        Expanded(
                          child: _StatCell(
                            icon: Icons.folder_rounded,
                            value: '${controller.totalCategories}',
                            label: 'Categories'.tr,
                            color: const Color(0xFF9B59B6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Friend Connection (Flush) ──────────────────────────────
                if (isLoggedIn) ...[
                  SizedBox(height: 12),
                  _SupportCard(
                    children: [
                      _SupportTile(
                        icon: Icons.link_rounded,
                        label: 'Copy Personal Link'.tr,
                        onTap: controller.copyPersonalFriendLink,
                      ),
                      _SupportTile(
                        icon: Icons.qr_code_2_rounded,
                        label: 'Show Personal QR'.tr,
                        onTap: () => Get.toNamed(MyQrPage.routeName),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  void _showAvatarBottomSheet(BuildContext context, User currentUser) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.d500,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacityCompat(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextWidget(
                  text: 'Avatar'.tr,
                  textStyle: AppTextStyle.bold18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),

              // 1. Xem ảnh đại diện
              _AvatarOptionTile(
                icon: Icons.account_circle_outlined,
                iconColor: AppColors.white.withOpacityCompat(0.7),
                title: 'View Avatar'.tr,
                onTap: () {
                  Get.back();
                  final photoUrl = currentUser.photoURL;
                  if (photoUrl != null && photoUrl.isNotEmpty) {
                    _viewAvatarFullScreen(context, photoUrl);
                  } else {
                    AppToast.showToast('No avatar available'.tr, Icons.info_outline_rounded);
                  }
                },
              ),
              Divider(height: 1, thickness: 0.5, color: AppColors.white.withOpacityCompat(0.06)),

              // 2. Chọn ảnh trên máy
              _AvatarOptionTile(
                icon: Icons.add_photo_alternate_outlined,
                iconColor: AppColors.white.withOpacityCompat(0.7),
                title: 'Choose photo from device'.tr,
                onTap: () {
                  Get.back();
                  controller.changeAvatar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewAvatarFullScreen(BuildContext context, String imageUrl) {
    Get.dialog(
      Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
            onPressed: () => Get.back(),
          ),
          title: TextWidget(text: 'Avatar'.tr, color: Colors.white, textStyle: AppTextStyle.bold18),
          centerTitle: true,
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.8,
            maxScale: 4.0,
            child: CacheImageWidget(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              errorWidget: const Icon(Icons.person, size: 100, color: Colors.white),
            ),
          ),
        ),
      ),
      useSafeArea: false,
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacityCompat(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextWidget(
                  text: value,
                  color: AppColors.white,
                  size: 19,
                  fontWeight: FontWeight.w700,
                ),
                TextWidget(text: label, color: AppColors.n60, size: 11.5, maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.d500,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.white.withOpacityCompat(0.06), width: 1),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 52,
                endIndent: 0,
                color: AppColors.white.withOpacityCompat(0.08),
              ),
          ],
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.n70, size: 21),
      title: TextWidget(text: label, color: AppColors.white, size: 14, fontWeight: FontWeight.w500),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.n400, size: 20)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minLeadingWidth: 24,
      dense: true,
    );
  }
}

class _AvatarOptionTile extends StatelessWidget {
  const _AvatarOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: TextWidget(
                text: title,
                color: AppColors.white,
                size: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
