import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImagePage extends StatefulWidget {
  final String imageUrl;
  final String? tagHero;

  const FullScreenImagePage({super.key, required this.imageUrl, this.tagHero});

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  double initialY = 0;
  double currentY = 0;
  double deltaY = 0;

  double opacity = 1;
  double disposeLimit = 150;

  Duration animationDuration = Duration.zero;

  void startVerticalDrag(DragStartDetails details) {
    initialY = details.globalPosition.dy;
  }

  void whileVerticalDrag(DragUpdateDetails details) {
    setState(() {
      currentY = details.globalPosition.dy;
      deltaY = currentY - initialY;

      double tmp = 1 - (deltaY.abs() / 1000);
      if (tmp < 0) tmp = 0;
      if (tmp > 1) tmp = 1;
      opacity = tmp;
    });
  }

  void endVerticalDrag(DragEndDetails details) {
    if (deltaY.abs() > disposeLimit) {
      Get.back();
    } else {
      setState(() {
        animationDuration = const Duration(milliseconds: 300);
        deltaY = 0;
        opacity = 1;
      });

      Future.delayed(animationDuration).then((_) {
        animationDuration = Duration.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacityCompat(opacity),
      body: GestureDetector(
        onVerticalDragStart: startVerticalDrag,
        onVerticalDragUpdate: whileVerticalDrag,
        onVerticalDragEnd: endVerticalDrag,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: animationDuration,
              top: deltaY,
              bottom: -deltaY,
              left: 0,
              right: 0,
              child: Center(
                child: Hero(
                  tag: widget.tagHero ?? widget.imageUrl,
                  child: PhotoView(
                    backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                    imageProvider: CachedNetworkImageProvider(
                      widget.imageUrl.trim(),
                      errorListener: (_) {},
                    ),
                    minScale: PhotoViewComputedScale.contained * 1,
                    maxScale: PhotoViewComputedScale.covered * 4,
                  ),
                ),
              ),
            ),

            /// Nút Back
            Positioned(
              top: 40,
              left: 15,
              right: 0,
              child: Row(
                children: [
                  AppVectors.icClose.show(
                    backgroundColor: AppColors.d300,
                    padding: EdgeInsets.all(8),
                    onTap: () {
                      Get.back();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
