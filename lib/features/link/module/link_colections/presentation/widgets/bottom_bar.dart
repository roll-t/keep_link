import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/features/link/module/link_add/presentation/page/add_link_page.dart';
import 'package:keep_link/features/link/module/link_search/presentation/page/search_link_page.dart';

// ─── Controller ───────────────────────────────────────────────────────────────

class BottomBarController extends GetxController {
  final selectedIndex = 0.obs;
  final isAddPressed = false.obs;

  void selectTab(int index) {
    selectedIndex.value = index;
    if (index == 0) {
      Get.toNamed(SearchLinkPage.routeName);
    } else if (index == 1) {}
  }

  Future<void> pressAdd(VoidCallback? onTap) async {
    isAddPressed.value = true;
    await Future.delayed(const Duration(milliseconds: 150));
    isAddPressed.value = false;
    onTap?.call();
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

// ─── Main widget ──────────────────────────────────────────────────────────────
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
        height: 100,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _DarkBar(items: _navItems, ctrl: ctrl),
            ),
            Positioned(
              top: 0,
              child: _AddButton(ctrl: ctrl, onTap: () => Get.toNamed(AddLinkPage.routeName)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dark bar với notch lõm ────────────────────────────────────────────────────
class _DarkBar extends StatelessWidget {
  final List<_NavItem> items;
  final BottomBarController ctrl;

  const _DarkBar({required this.items, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: CustomPaint(
        painter: _NotchPainter(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItemWidget(item: items[0], index: 0, ctrl: ctrl),
              const SizedBox(width: 90),
              _NavItemWidget(item: items[1], index: 1, ctrl: ctrl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Custom painter vẽ bar tối với lõm tròn ở giữa ───────────────────────────
class _NotchPainter extends CustomPainter {
  static const _notchWidth = 50.0; // Độ rộng miệng hố (tăng nhẹ để cân đối với độ sâu)
  static const _notchDepth = 42.0; // Độ sâu (đã tăng thêm để lõm sâu hẳn xuống)
  static const _barRadius = 28.0; // Bo góc thanh bar
  static const _smoothness = 20.0; // Tăng độ miết để đường vào hố mượt hơn

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 30, 35, 46)
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;

    // Bắt đầu vẽ từ góc trái
    path.moveTo(0, _barRadius);
    path.quadraticBezierTo(0, 0, _barRadius, 0);

    // 1. Đi đến điểm bắt đầu miết (cách xa miệng hố hơn để cua rộng)
    path.lineTo(centerX - _notchWidth - _smoothness, 0);

    // 2. Miết xuống đáy hố (Dùng Cubic để tạo độ cong mềm)
    // Điểm điều khiển 1: (centerX - _notchWidth, 0) - Giữ đường đi ngang một chút
    // Điểm điều khiển 2: (centerX - _notchWidth + 10, _notchDepth) - Kéo sâu xuống đáy
    path.cubicTo(
      centerX - _notchWidth,
      0,
      centerX - _notchWidth + 10,
      _notchDepth,
      centerX,
      _notchDepth,
    );

    // 3. Miết ngược lên lại
    path.cubicTo(
      centerX + _notchWidth - 10,
      _notchDepth,
      centerX + _notchWidth,
      0,
      centerX + _notchWidth + _smoothness,
      0,
    );

    // 4. Đi tiếp đến góc phải và hoàn thiện khung
    path.lineTo(size.width - _barRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, _barRadius);
    path.lineTo(size.width, size.height - _barRadius);
    path.quadraticBezierTo(size.width, size.height, size.width - _barRadius, size.height);
    path.lineTo(_barRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - _barRadius);

    path.close();

    // Shadow đậm hơn một chút để thấy rõ độ sâu
    canvas.drawShadow(path, AppColors.black.withOpacityCompat(0.7), 15, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
// ─── Nav item ─────────────────────────────────────────────────────────────────

class _NavItemWidget extends StatelessWidget {
  final _NavItem item;
  final int index;
  final BottomBarController ctrl;

  const _NavItemWidget({required this.item, required this.index, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: IconButton(
          onPressed: () => ctrl.selectTab(index),
          icon: Icon(item.icon, color: Color.fromARGB(255, 103, 110, 255), size: 30),
        ),
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
          curve: Curves.easeInOut,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.fromARGB(255, 149, 197, 255), AppColors.primary, AppColors.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacityCompat(0.5),
                  blurRadius: pressed ? 8 : 20,
                  spreadRadius: pressed ? 0 : 3,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedRotation(
              turns: pressed ? 0.125 : 0.0,
              duration: const Duration(milliseconds: 120),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
            ),
          ),
        );
      }),
    );
  }
}
