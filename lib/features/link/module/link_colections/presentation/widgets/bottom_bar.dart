import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/features/link/module/link_add/presentation/page/add_link_page.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/controller/link_collection_controller.dart';
import 'package:keep_link/features/link/module/link_search/presentation/page/search_link_page.dart';
import 'package:keep_link/features/personal/presentation/page/personal_page.dart';

// ─── Controller (Giữ nguyên) ───────────────────────────────────────────────────
class BottomBarController extends GetxController with GetSingleTickerProviderStateMixin {
  final selectedIndex = 0.obs;
  final isAddPressed = false.obs;
  late AnimationController pulseController;

  @override
  void onInit() {
    super.onInit();
    pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
  }

  @override
  void onClose() {
    pulseController.dispose();
    super.onClose();
  }

  void selectTab(int index) {
    selectedIndex.value = index;
    if (index == 0) {
      Get.toNamed(SearchLinkPage.routeName);
    } else if (index == 1) {
      Get.toNamed(PersonalPage.routeName);
    }
  }

  Future<void> pressAdd(VoidCallback? onTap) async {
    isAddPressed.value = true;
    await Future.delayed(const Duration(milliseconds: 150));
    isAddPressed.value = false;
    onTap?.call();
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

// ─── Main widget (Chỉnh Stack để nút nhô cao) ──────────────────────────────────
class GlassBottomBar extends StatelessWidget {
  const GlassBottomBar({super.key});

  static final _navItems = [
    _NavItem(Icons.search_rounded, 'Search'),
    _NavItem(Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(BottomBarController());
    final sidePadding = MediaQuery.sizeOf(context).width * 0.12;

    return Padding(
      padding: EdgeInsets.only(left: sidePadding, right: sidePadding),
      child: SizedBox(
        height: 85, // Tăng chiều cao tổng để có không gian nhô lên
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Thanh Menu bo tròn phẳng phía dưới
            _DarkBar(items: _navItems, ctrl: ctrl),

            // Nút Add nằm ở vị trí cao hơn hẳn
            Positioned(
              top: 0, // Đưa lên sát đỉnh của SizedBox
              child: _AddButton(
                ctrl: ctrl,
                onTap: () => Get.toNamed(AddLinkPage.routeName)?.then((success) {
                  if (success is bool && success) {
                    Get.find<LinkCollectionController>().refreshData();
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Glass Bar phẳng bo tròn 2 đầu ───────────────────────────────────────────
class _DarkBar extends StatelessWidget {
  final List<_NavItem> items;
  final BottomBarController ctrl;

  const _DarkBar({required this.items, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    const barRadius = BorderRadius.all(Radius.circular(30));

    return Container(
      height: 60, // Chiều cao thanh menu thấp hơn SizedBox tổng
      decoration: BoxDecoration(
        borderRadius: barRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacityCompat(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: barRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 30, 35, 46).withOpacityCompat(0.75),
              borderRadius: barRadius,
              border: Border.all(color: Colors.white.withOpacityCompat(0.12), width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavItemWidget(item: items[0], index: 0, ctrl: ctrl),
                  SizedBox(width: 60),
                  _NavItemWidget(item: items[1], index: 1, ctrl: ctrl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Các component hỗ trợ (Giữ nguyên logic animation thở) ─────────────────────
class _NavItemWidget extends StatelessWidget {
  final _NavItem item;
  final int index;
  final BottomBarController ctrl;
  const _NavItemWidget({required this.item, required this.index, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: IconButton(
        onPressed: () => ctrl.selectTab(index),
        icon: Icon(item.icon, color: const Color.fromARGB(255, 103, 110, 255), size: 28),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final BottomBarController ctrl;
  final VoidCallback? onTap;
  const _AddButton({required this.ctrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ctrl.pressAdd(onTap),
      child: Obx(() {
        final pressed = ctrl.isAddPressed.value;
        return AnimatedScale(
          scale: pressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutBack,
          child: AnimatedBuilder(
            animation: ctrl.pulseController,
            builder: (context, child) {
              final value = ctrl.pulseController.value;
              final shadowSpread = 15.0 + (value * 10.0);
              final shadowOpacity = 0.3 + (value * 0.2);

              return Container(
                width: 62, // Tăng nhẹ kích thước nút Add
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment(0, -1.0 + (value * 0.5)),
                    end: Alignment(0, 1.0 + (value * 0.5)),
                    colors: const [
                      Color.fromARGB(255, 149, 197, 255),
                      AppColors.primary,
                      Color.fromARGB(255, 120, 160, 255),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacityCompat(pressed ? 0.2 : shadowOpacity),
                      blurRadius: pressed ? 10 : shadowSpread,
                      spreadRadius: pressed ? 0 : (value * 4),
                      offset: Offset(0, 4 + (value * 2)),
                    ),
                  ],
                ),
                child: const Center(child: Icon(Icons.add_rounded, color: Colors.white, size: 36)),
              );
            },
          ),
        );
      }),
    );
  }
}
