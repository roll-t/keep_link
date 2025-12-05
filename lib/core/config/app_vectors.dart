import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:keep_link/core/config/app_colors.dart';

class AppVectors {
  static const String _root = "assets/vectors/";
  static const String _ext = ".svg";
  static const icSetting = _SvgIcon("${_root}ic_setting$_ext");
  static const icAddLink = _SvgIcon("${_root}ic_add_link$_ext");
  static const icAdd = _SvgIcon("${_root}ic_add$_ext");
  static const icArrowDown = _SvgIcon("${_root}ic_arrow_down$_ext");
  static const icEdit = _SvgIcon("${_root}ic_edit$_ext");
  static const icClose = _SvgIcon("${_root}ic_close$_ext");
  static const icClipBoard = _SvgIcon("${_root}ic_clip_board$_ext");
  static const icEmpty = _SvgIcon("${_root}ic_empty$_ext");
  static const icDelete = _SvgIcon("${_root}ic_delete$_ext");
  static const icPin = _SvgIcon("${_root}ic_pin$_ext");
  static const icFinger = _SvgIcon("${_root}ic_finger$_ext");
}

class _SvgIcon {
  final String path;
  const _SvgIcon(this.path);

  Widget show({
    double size = 25,
    Color? color,
    VoidCallback? onTap,
    EdgeInsets? padding,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
        child: SvgPicture.asset(
          path,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color ?? AppColors.white, BlendMode.srcIn),
        ),
      ),
    );
  }

  String get raw => path;
}
