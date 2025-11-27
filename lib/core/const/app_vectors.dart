import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppVectors {
  static const String _root = "assets/vectors/";
  static const String _ext = ".svg";
  static const icSetting = _SvgIcon("${_root}ic_setting$_ext");
  static const icUser = _SvgIcon("${_root}ic_user$_ext");
  static const icHome = _SvgIcon("${_root}ic_home$_ext");
  static const icCategory = _SvgIcon("${_root}ic_category$_ext");
  static const icNotUrl = _SvgIcon("${_root}ic_not_url$_ext");
  static const icPointer = _SvgIcon("${_root}ic_pointer$_ext");
  static const icCar = _SvgIcon("${_root}ic_car$_ext");
  static const icCredit = _SvgIcon("${_root}ic_credit$_ext");
  static const icMoney = _SvgIcon("${_root}ic_money$_ext");
  static const icDiamond = _SvgIcon("${_root}ic_diamon$_ext");
  static const icPeople = _SvgIcon("${_root}ic_people$_ext");
  static const icDashboard = _SvgIcon("${_root}ic_dashboard$_ext");
  static const icNoImage = _SvgIcon("${_root}ic_no_image$_ext");
  static const icArrowBack = _SvgIcon("${_root}ic_arrow_back$_ext");
  static const icSearch = _SvgIcon("${_root}ic_search$_ext");
  static const icArrowDropDown = _SvgIcon("${_root}ic_arrow_drop_down$_ext");
  static const icFilter = _SvgIcon("${_root}ic_filter$_ext");
  static const icArrowRight = _SvgIcon("${_root}ic_arrow_right$_ext");
  static const icArrowDown = _SvgIcon("${_root}ic_arrow_down$_ext");
  static const icArrowUp = _SvgIcon("${_root}ic_arrow_up$_ext");
  static const icList = _SvgIcon("${_root}ic_list$_ext");
  static const icEditing = _SvgIcon("${_root}ic_editing$_ext");
  static const icDelete = _SvgIcon("${_root}ic_delete$_ext");
  static const icIncrease = _SvgIcon("${_root}ic_increase$_ext");
  static const icDecrease = _SvgIcon("${_root}ic_decrease$_ext");
  static const icChart = _SvgIcon("${_root}ic_chart$_ext");
  static const icManage = _SvgIcon("${_root}ic_manage$_ext");
  static const icCash = _SvgIcon("${_root}ic_cash$_ext");
  static const icDate = _SvgIcon("${_root}ic_date$_ext");
  static const icFinance = _SvgIcon("${_root}ic_finance$_ext");
  static const icPerson = _SvgIcon("${_root}ic_person$_ext");
  static const icBookcase = _SvgIcon("${_root}ic_bookcase$_ext");
  static const icBook = _SvgIcon("${_root}ic_book$_ext");
  static const icCurrency = _SvgIcon("${_root}ic_currency$_ext");
  static const icAdd = _SvgIcon("${_root}ic_add$_ext");
  static const icHistory = _SvgIcon("${_root}ic_history$_ext");
}

class _SvgIcon {
  final String path;
  const _SvgIcon(this.path);

  Widget show({
    double size = 25,
    Color? color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SvgPicture.asset(
        path,
        width: size,
        height: size,
        colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
      ),
    );
  }

  String get raw => path;
}
