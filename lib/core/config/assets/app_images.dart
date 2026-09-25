import 'package:flutter/material.dart';

class AppImages {
  static const String _root = "assets/images/";
  static const String _ext = ".png";
  static const iLogoApp = _PngImage("${_root}i_logo_app$_ext");
  static const iLogoFull = _PngImage("${_root}i_logo_full$_ext");
  static const iQr1 = _PngImage("${_root}i_qr_1$_ext");
  static const iQr2 = _PngImage("${_root}i_qr_2$_ext");
  static const iQr3 = _PngImage("${_root}i_qr_3$_ext");
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
