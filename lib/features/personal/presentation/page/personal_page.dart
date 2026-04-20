import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/core/ui/appbar/custom_app_bar.dart';
import 'package:keep_link/core/ui/image/cache_image.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/personal/presentation/controller/personal_controller.dart';

class PersonalPage extends GetView<PersonalController> {
  static const routeName = '/PersonalPage';
  const PersonalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg700,
      appBar: CustomAppBar(title: "Personal".tr),
      body: Obx(() {
        final currentUser = controller.user.value;
        final loading = controller.isLoading.value;
        final isLoggedIn = currentUser != null;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.d300,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
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
                        child: const Icon(Icons.person, size: 34, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextWidget(
                      text: isLoggedIn
                          ? (currentUser.displayName?.isNotEmpty == true
                                ? currentUser.displayName!
                                : 'No display name'.tr)
                          : 'Guest User'.tr,
                      color: Colors.white,
                      size: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 6),
                    TextWidget(
                      text: isLoggedIn ? (currentUser.email ?? 'No email'.tr) : 'Not signed in'.tr,
                      color: Colors.white70,
                      size: 14,
                    ),
                    if (isLoggedIn) ...[
                      const SizedBox(height: 6),
                      TextWidget(
                        text: 'UID: @0'.trParams({'0': currentUser.uid}),
                        color: Colors.white54,
                        size: 12,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
            ],
          ),
        );
      }),
    );
  }
}
