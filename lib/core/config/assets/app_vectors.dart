import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';

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
  static const icLock = _SvgIcon("${_root}ic_lock$_ext");
  static const icWarning = _SvgIcon("${_root}ic_warning$_ext");
  static const icCopy = _SvgIcon("${_root}ic_copy$_ext");
  static const icFloatingExtension = _SvgIcon("${_root}ic_floating_extension$_ext");
  static const icSearch = _SvgIcon("${_root}ic_search$_ext");
  static const icSearchNotFound = _SvgIcon("${_root}ic_search_not_found$_ext");
  static const icSearchFile = _SvgIcon("${_root}ic_search_file$_ext");
  static const icLang = _SvgIcon("${_root}ic_lang$_ext");
  static const icFriends = _SvgIcon("${_root}ic_friends$_ext");
}

class _SvgIcon {
  final String path;
  const _SvgIcon(this.path);

  Widget show({
    double size = 25,
    Color? color,
    VoidCallback? onTap,
    EdgeInsets? padding,
    double? widthParent,
    double? heightParent,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
        width: widthParent,
        height: heightParent ?? widthParent,
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
