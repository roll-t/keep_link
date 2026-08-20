import 'package:flutter/material.dart';

class AppImages {
  static const String _root = "assets/images/";
  static const String _ext = ".png";

  static const iLogo = _PngImage("${_root}i_logo$_ext");
  static const iBgSplash = _PngImage("${_root}i_bg_splash$_ext");
}

class _PngImage {
  final String path;
  const _PngImage(this.path);

  Widget show({
    double? width,
    double? height,
    double? size, // nếu muốn dùng size chung
    BoxFit fit = BoxFit.contain,
    Color? color,
    EdgeInsets? padding,
    Alignment? align,
    VoidCallback? onTap,
  }) {
    final img = GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Image.asset(
          path,
          width: size ?? width,
          height: size ?? height,
          fit: fit,
          color: color,
        ),
      ),
    );

    if (align != null) {
      return Align(alignment: align, child: img);
    } else {
      return img;
    }
  }

  String get raw => path;
}
