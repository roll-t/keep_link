import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';

class ImageView extends StatefulWidget {
  const ImageView({
    super.key,
    required this.listImageUrl,
    this.backgroundColor = Colors.black,
    this.backgroundIsTransparent = true,
    this.listTagHero = const [],
    this.initIndexImage = 0,
    this.onTap,
    this.isViewInComment = false,
  });

  final List<String> listImageUrl;
  final List<String> listTagHero;
  final Color backgroundColor;
  final bool backgroundIsTransparent;
  final int initIndexImage;
  final Function? onTap;
  final bool? isViewInComment;
  @override
  ImageViewState createState() => ImageViewState();
}

class ImageViewState extends State<ImageView> {
  late PageController pageController;

  double initialPositionY = 0;

  double currentPositionY = 0;

  double positionYDelta = 0;

  double initialPositionX = 0;

  double currentPositionX = 0;

  double positionXDelta = 0;

  double opacity = 1;

  double disposeLimit = 150;

  Duration animationDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.listTagHero.removeWhere((element) => element.isEmpty);
    pageController = PageController(initialPage: widget.initIndexImage);
  }

  void _startVerticalDrag(details) {
    setState(() {
      initialPositionY = details.globalPosition.dy;
    });
  }

  void _startHorizontalDrag(DragStartDetails details) {
    setState(() {
      initialPositionX = details.globalPosition.dx;
    });
  }

  void _whileVerticalDrag(details) {
    setState(() {
      currentPositionY = details.globalPosition.dy;
      positionYDelta = currentPositionY - initialPositionY;
      setOpacity();
    });
  }

  void _whileHorizontalDrag(DragUpdateDetails details) {
    setState(() {
      currentPositionX = details.globalPosition.dx;
      positionXDelta = initialPositionX - currentPositionX;
      setOpacity();
    });
  }

  setOpacity() {
    double tmp = positionYDelta < 0
        ? 1 - ((positionYDelta / 1000) * -1)
        : 1 - (positionYDelta / 1000);

    if (tmp > 1) {
      opacity = 1;
    } else if (tmp < 0) {
      opacity = 0;
    } else {
      opacity = tmp;
    }

    if (positionYDelta > disposeLimit || positionYDelta < -disposeLimit) {
      opacity = 0.5;
    }
  }

  _endVerticalDrag(DragEndDetails details) {
    if (positionYDelta > disposeLimit || positionYDelta < -disposeLimit) {
      Get.back();
    } else {
      setState(() {
        animationDuration = const Duration(milliseconds: 300);
        opacity = 1;
        positionYDelta = 0;
      });

      Future.delayed(animationDuration).then((_) {
        setState(() {
          animationDuration = Duration.zero;
        });
      });
    }
  }

  _endHorizontalDrag(DragEndDetails details) {
    if (positionXDelta > 0.3 || positionXDelta < -0.3) {
      Get.back();
    } else {
      setState(() {
        animationDuration = const Duration(milliseconds: 300);
        opacity = 1;
        positionXDelta = 0;
      });

      Future.delayed(animationDuration).then((_) {
        setState(() {
          animationDuration = Duration.zero;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundIsTransparent ? Colors.black : widget.backgroundColor,
      // appBar: AppBarWidget(
      //   isLeading: true,
      //   callbackLeading: () => Get.back(),
      //   iconLeadingColor: AppColors.white,
      //   backgroundColor: AppColors.transparent,
      //   menuItem: [
      //     // IconButton(
      //     //   onPressed: () async {
      //     //     if (widget.onTap != null) {
      //     //       await widget.onTap?.call();
      //     //     }
      //     //   },
      //     //   icon: const Icon(
      //     //     Icons.more_vert,
      //     //     size: 30.0,
      //     //   ),
      //     // )
      //   ],
      // ),
      body: GestureDetector(
        onVerticalDragStart: (details) => _startVerticalDrag(details),
        onVerticalDragUpdate: (details) => _whileVerticalDrag(details),
        onVerticalDragEnd: (details) => _endVerticalDrag(details),
        onHorizontalDragStart: (details) => _startHorizontalDrag(details),
        onHorizontalDragUpdate: (details) => _whileHorizontalDrag(details),
        onHorizontalDragEnd: (details) => _endHorizontalDrag(details),
        child: Container(
          color: widget.backgroundColor.withOpacityCompat(opacity),
          constraints: BoxConstraints.expand(height: MediaQuery.of(context).size.height),
          child: Stack(
            children: <Widget>[
              AnimatedPositioned(
                duration: animationDuration,
                curve: Curves.fastOutSlowIn,
                top: 0 + positionYDelta,
                bottom: 0 - positionYDelta,
                left: 0 - positionXDelta,
                right: positionXDelta,
                child: PhotoViewGallery.builder(
                  pageController: pageController,
                  itemCount: widget.listImageUrl.length,
                  builder: (_, index) {
                    bool isHttpUrl = GetUtils.isURL(widget.listImageUrl[index]);
                    if (isHttpUrl) {
                      return PhotoViewGalleryPageOptions.customChild(
                        child: CachedNetworkImage(
                          imageUrl: widget.listImageUrl[index],
                          errorListener: (_) {},
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          imageBuilder: (context, imageProvider) => PhotoView(
                            imageProvider: imageProvider,
                            heroAttributes: widget.listTagHero.isEmpty
                                ? null
                                : PhotoViewHeroAttributes(tag: widget.listTagHero[index]),
                          ),
                          errorWidget: (context, _, __) => const Center(
                            child: TextWidget(
                              text: 'Đã xảy ra lỗi. Vui lòng thử lại!',
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return PhotoViewGalleryPageOptions.customChild(
                        child: Image.file(File(widget.listImageUrl[index]), fit: BoxFit.contain),
                      );
                    }
                  },
                ),
              ),
              Positioned(
                top: 25,
                left: 10,
                right: 10,
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/ic_arrow_left_2.svg',
                          colorFilter: ColorFilter.mode(AppColors.white, BlendMode.srcIn),
                        ),
                        onPressed: () => Get.back(),
                      ),
                      // if ((widget.isViewInComment ?? false))
                      //   IconButtonCustom(
                      //     onPressed: () async {
                      //       if (widget.onTap != null) {
                      //         await widget.onTap?.call();
                      //       }
                      //     },
                      //     icon: const Icon(Icons.more_vert, size: 26.0, color: AppColors.white),
                      //   ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
