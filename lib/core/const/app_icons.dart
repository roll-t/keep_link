import 'package:flutter/material.dart';

class AppIcons {
  static const String _root = "assets/icons/";
  static const String _ext = ".png";

  static const icNoData = _PngIcon("${_root}ic_no_data$_ext");
  static const icAddFood = _PngIcon("${_root}ic_add_food$_ext");
  static const icHandCat = _PngIcon("${_root}ic_hand_cat$_ext");
  static const icCenterWheel = _PngIcon("${_root}ic_center_wheel$_ext");
  static const icAskAi = _PngIcon("${_root}ic_ask_ai$_ext");
  static const icHistory = _PngIcon("${_root}ic_history$_ext");
  static const icClose = _PngIcon("${_root}ic_close$_ext");
  static const icAdd = _PngIcon("${_root}ic_add$_ext");
  static const icCloseV2 = _PngIcon("${_root}ic_close_v2$_ext");
  static const icTick = _PngIcon("${_root}ic_tick$_ext");
  static const icDelete = _PngIcon("${_root}ic_delete$_ext");
  static const icEmptyData = _PngIcon("${_root}ic_empty_data$_ext");
  static const icWheelMark = _PngIcon("${_root}ic_wheel_mark$_ext");
  static const icLogoTiktok = _PngIcon("${_root}ic_logo_tiktok$_ext");
  static const icLogoTwitter = _PngIcon("${_root}ic_logo_twitter$_ext");
  static const icLogoInstagram = _PngIcon("${_root}ic_logo_instagram$_ext");
  static const icLogoFacebook = _PngIcon("${_root}ic_logo_facebook$_ext");
  static const icLogoYoutube = _PngIcon("${_root}ic_logo_youtube$_ext");
  static const icLogoGoogle = _PngIcon("${_root}ic_google$_ext");
  static const icCatNoData = _PngIcon("${_root}ic_cat_no_data$_ext");
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
        child: Image.asset(
          path,
          width: size,
          height: size,
          fit: fit,
          color: color,
        ),
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
