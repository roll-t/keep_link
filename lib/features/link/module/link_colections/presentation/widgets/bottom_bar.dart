import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/features/link/module/link_add/presentation/page/add_link_page.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/link_collection_controller.dart';
import 'package:keep_link/features/link/module/link_search/presentation/page/search_link_page.dart';
import 'package:keep_link/features/personal/presentation/page/personal_page.dart';

class BottomBarController extends GetxController {
  final isAddPressed = false.obs;
  bool _isNavigating = false;

  Future<void> openPage(String routeName) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      await Get.toNamed(routeName);
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> addLink() async {
    if (_isNavigating) return;
    _isNavigating = true;
    isAddPressed.value = true;
    HapticFeedback.lightImpact();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 90));
      isAddPressed.value = false;
      final result = await Get.toNamed(AddLinkPage.routeName);
      if (result == true && Get.isRegistered<LinkCollectionController>()) {
        Get.find<LinkCollectionController>().refreshData();
      }
    } finally {
      isAddPressed.value = false;
      _isNavigating = false;
    }
  }
}

/// Dock điều hướng trên màn hình thư viện.
///
/// Tìm kiếm và Cá nhân là các hành động mở trang mới, không phải tab được chọn,
/// vì vậy thanh này không hiển thị trạng thái selected gây hiểu nhầm.
class GlassBottomBar extends StatelessWidget {
  const GlassBottomBar({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BottomBarController());
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Chiều rộng lý tưởng cho dock gồm 2 tab + 1 nút Add ở giữa là ~210 - 224px.
    // Dùng clamp:
    // - Khóa tối đa 224px để không bị bè ngang, dư khoảng trống trên màn hình lớn / tablet.
    // - Giảm về tối thiểu 190px trên màn hình siêu nhỏ để không bị tràn viền.
    final dockWidth = (screenWidth - 100).clamp(190.0, 224.0);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: SizedBox(
        width: dockWidth,
        height: 62,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            _NavigationDock(controller: controller),
            Positioned(top: 0, child: _AddButton(controller: controller)),
          ],
        ),
      ),
    );
  }
}

class _NavigationDock extends StatelessWidget {
  const _NavigationDock({required this.controller});

  final BottomBarController controller;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(20));

    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacityCompat(.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.navigationSurface.withOpacityCompat(.98),
            borderRadius: radius,
            border: Border.all(color: AppColors.white.withOpacityCompat(.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _DockAction(
                  icon: Icons.search_rounded,
                  label: 'Search'.tr,
                  onTap: () => controller.openPage(SearchLinkPage.routeName),
                ),
              ),
              const SizedBox(width: 64),
              Expanded(
                child: _DockAction(
                  icon: Icons.person_outline_rounded,
                  label: 'Personal'.tr,
                  onTap: () => controller.openPage(PersonalPage.routeName),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockAction extends StatelessWidget {
  const _DockAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(18),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.primaryContainer, size: 20),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.n70,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.controller});

  final BottomBarController controller;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add Link'.tr,
      child: Semantics(
        button: true,
        label: 'Add Link'.tr,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: controller.addLink,
          child: Obx(() {
            final pressed = controller.isAddPressed.value;
            return AnimatedScale(
              scale: pressed ? .9 : 1,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryBright, AppColors.primary],
                  ),
                  border: Border.all(
                    color: AppColors.navigationSurface,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacityCompat(.32),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.white,
                  size: 26,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
