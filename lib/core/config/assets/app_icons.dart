import 'package:flutter/material.dart';

class AppIcons {
  static const String _root = "assets/icons/";
  static const String _ext = ".png";

  static const icNoData = _PngIcon("${_root}ic_no_data$_ext");
  static const icLogoTiktok = _PngIcon("${_root}ic_logo_tiktok$_ext");
  static const icLogoTwitter = _PngIcon("${_root}ic_logo_twitter$_ext");
  static const icLogoInstagram = _PngIcon("${_root}ic_logo_instagram$_ext");
  static const icLogoFacebook = _PngIcon("${_root}ic_logo_facebook$_ext");
  static const icLogoYoutube = _PngIcon("${_root}ic_logo_youtube$_ext");
  static const icLogoGoogle = _PngIcon("${_root}ic_logo_google$_ext");
}

class _PngIcon {
  final String path;
  const _PngIcon(this.path);
  Widget show({
    double size = 25,
    BoxFit fit = BoxFit.contain,
    Color? color,
    EdgeInsets? padding,
    VoidCallback? onTap,
    Alignment? align,
  }) {
    final content = GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Image.asset(path, width: size, height: size, fit: fit, color: color),
      ),
    );

    if (align != null) {
      return Align(alignment: align, child: content);
    } else {
      return content;
    }
  }

  String get raw => path;
}
