import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/cache/app_cache.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/core/ui/appbar/custom_app_bar.dart';
import 'package:keep_link/core/ui/image/cache_image.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/personal/presentation/controller/personal_controller.dart';
import 'package:keep_link/features/personal/presentation/page/privacy_policy_page.dart';
import 'package:keep_link/features/personal/presentation/page/terms_page.dart';

class PersonalPage extends GetView<PersonalController> {
  static const routeName = '/PersonalPage';

  const PersonalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.bg700,
        appBar: CustomAppBar(title: "Personal".tr),
        body: Obx(() {
          final currentUser = controller.user.value;
          final loading = controller.isLoading.value;
          final isLoggedIn = currentUser != null;
          AppCache.links.length;
          AppCache.categories.length;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Profile card ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.d500,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      // ── Avatar ──────────────────────────────────────────
                      Obx(() {
                        final uploading = controller.isUploadingAvatar.value;
                        return GestureDetector(
                          onTap: isLoggedIn && !uploading ? controller.changeAvatar : null,
                          child: Stack(
                            children: [
                              CacheImageWidget(
                                imageUrl: isLoggedIn && (currentUser.photoURL?.isNotEmpty == true)
                                    ? currentUser.photoURL!
                                    : '',
                                width: 68,
                                height: 68,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(34),
                                errorWidget: Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacityCompat(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person, size: 34, color: AppColors.white),
                                ),
                              ),
                              if (uploading)
                                Container(
                                  width: 68,
                                  height: 68,
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
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.d500, width: 1.5),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      size: 11,
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
                            fontWeight: FontWeight.w600,
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
                      const SizedBox(height: 6),
                      TextWidget(
                        text: isLoggedIn
                            ? (currentUser.email ?? 'No email'.tr)
                            : 'Not signed in'.tr,
                        color: AppColors.n70,
                        size: 14,
                      ),
                      if (isLoggedIn) ...[
                        const SizedBox(height: 6),
                        TextWidget(
                          text: 'UID: @0'.trParams({'0': currentUser.uid}),
                          color: AppColors.n60,
                          size: 12,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Sign in / out ─────────────────────────────────────────────
                ElevatedButton.icon(
                  onPressed: loading
                      ? null
                      : (isLoggedIn ? controller.signOut : controller.signInWithGoogle),
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(isLoggedIn ? Icons.logout_rounded : Icons.login_rounded),
                  label: TextWidget(
                    text: loading
                        ? 'Please wait...'.tr
                        : (isLoggedIn ? 'Sign Out'.tr : 'Sign In with Google'.tr),
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Stats ─────────────────────────────────────────────────────
                _SectionLabel(label: 'Statistics'.tr),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.link_rounded,
                        value: '${controller.totalLinks}',
                        label: 'Total Links'.tr,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.folder_rounded,
                        value: '${controller.totalCategories}',
                        label: 'Categories'.tr,
                        color: const Color(0xFF9B59B6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.calendar_today_rounded,
                        value: '${controller.linksThisWeek}',
                        label: 'This Week'.tr,
                        color: const Color(0xFF27AE60),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        value: '${controller.currentStreak}',
                        label: 'Day Streak'.tr,
                        color: const Color(0xFFE67E22),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Support ───────────────────────────────────────────────────
                _SectionLabel(label: 'Support'.tr),
                const SizedBox(height: 8),
                _SupportCard(
                  children: [
                    _SupportTile(
                      icon: Icons.star_rounded,
                      label: 'Rate App'.tr,
                      onTap: controller.rateApp,
                    ),
                    _SupportTile(
                      icon: Icons.feedback_rounded,
                      label: 'Send Feedback'.tr,
                      onTap: controller.sendFeedback,
                    ),
                    _SupportTile(
                      icon: Icons.bug_report_rounded,
                      label: 'Report a Bug'.tr,
                      onTap: controller.reportBug,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SupportCard(
                  children: [
                    _SupportTile(
                      icon: Icons.privacy_tip_rounded,
                      label: 'Privacy Policy'.tr,
                      onTap: () => Get.toNamed(PrivacyPolicyPage.routeName),
                    ),
                    _SupportTile(
                      icon: Icons.description_rounded,
                      label: 'Terms of Service'.tr,
                      onTap: () => Get.toNamed(TermsPage.routeName),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SupportCard(
                  children: [
                    Obx(
                      () => _SupportTile(
                        icon: Icons.info_outline_rounded,
                        label: 'App Version'.tr,
                        trailing: TextWidget(
                          text: controller.appVersion.value,
                          color: Colors.white38,
                          size: 13,
                        ),
                        onTap: null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextWidget(text: label, color: Colors.white54, size: 12, fontWeight: FontWeight.w600);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(color: AppColors.d500, borderRadius: BorderRadius.circular(14)),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: value,
                color: AppColors.white,
                size: 20,
                fontWeight: FontWeight.w700,
              ),
              TextWidget(text: label, color: AppColors.n60, size: 12),
            ],
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
      decoration: BoxDecoration(color: AppColors.d500, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: .5, indent: 52, color: AppColors.n500.withOpacityCompat(0.5)),
          ],
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({required this.icon, required this.label, required this.onTap, this.trailing});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.n70, size: 20),
      title: TextWidget(text: label, color: AppColors.white, size: 14),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded, color: AppColors.n400, size: 20)
              : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      dense: true,
    );
  }
}
