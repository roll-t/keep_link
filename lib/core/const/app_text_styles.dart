import 'package:flutter/material.dart';

class AppTextStyleModel {
  final double fontSize;
  final FontWeight fontWeight;

  const AppTextStyleModel({
    required this.fontSize,
    required this.fontWeight,
  });
}

class AppTextStyle {
  // Regular
  static const regular24 =
      AppTextStyleModel(fontSize: 24, fontWeight: FontWeight.w400);
  static const regular20 =
      AppTextStyleModel(fontSize: 20, fontWeight: FontWeight.w400);
  static const regular18 =
      AppTextStyleModel(fontSize: 18, fontWeight: FontWeight.w400);
  static const regular16 =
      AppTextStyleModel(fontSize: 16, fontWeight: FontWeight.w400);
  static const regular14 =
      AppTextStyleModel(fontSize: 14, fontWeight: FontWeight.w400);
  static const regular12 =
      AppTextStyleModel(fontSize: 12, fontWeight: FontWeight.w400);
  static const regular10 =
      AppTextStyleModel(fontSize: 10, fontWeight: FontWeight.w400);

  // Medium
  static const medium24 =
      AppTextStyleModel(fontSize: 24, fontWeight: FontWeight.w500);
  static const medium20 =
      AppTextStyleModel(fontSize: 20, fontWeight: FontWeight.w500);
  static const medium18 =
      AppTextStyleModel(fontSize: 18, fontWeight: FontWeight.w500);
  static const medium16 =
      AppTextStyleModel(fontSize: 16, fontWeight: FontWeight.w500);
  static const medium14 =
      AppTextStyleModel(fontSize: 14, fontWeight: FontWeight.w500);
  static const medium12 =
      AppTextStyleModel(fontSize: 12, fontWeight: FontWeight.w500);
  static const medium10 =
      AppTextStyleModel(fontSize: 10, fontWeight: FontWeight.w500);

  // SemiBold
  static const semiBold24 =
      AppTextStyleModel(fontSize: 24, fontWeight: FontWeight.w600);
  static const semiBold20 =
      AppTextStyleModel(fontSize: 20, fontWeight: FontWeight.w600);
  static const semiBold18 =
      AppTextStyleModel(fontSize: 18, fontWeight: FontWeight.w600);
  static const semiBold16 =
      AppTextStyleModel(fontSize: 16, fontWeight: FontWeight.w600);
  static const semiBold14 =
      AppTextStyleModel(fontSize: 14, fontWeight: FontWeight.w600);
  static const semiBold12 =
      AppTextStyleModel(fontSize: 12, fontWeight: FontWeight.w600);
  static const semiBold10 =
      AppTextStyleModel(fontSize: 10, fontWeight: FontWeight.w600);

  // Bold
  static const bold40 =
      AppTextStyleModel(fontSize: 40, fontWeight: FontWeight.w700);
  static const bold30 =
      AppTextStyleModel(fontSize: 30, fontWeight: FontWeight.w700);
  static const bold36 =
      AppTextStyleModel(fontSize: 30, fontWeight: FontWeight.w700);
  static const bold28 =
      AppTextStyleModel(fontSize: 24, fontWeight: FontWeight.w700);
  static const bold24 =
      AppTextStyleModel(fontSize: 24, fontWeight: FontWeight.w700);
  static const bold22 =
      AppTextStyleModel(fontSize: 22, fontWeight: FontWeight.w700);
  static const bold20 =
      AppTextStyleModel(fontSize: 20, fontWeight: FontWeight.w700);
  static const bold18 =
      AppTextStyleModel(fontSize: 18, fontWeight: FontWeight.w700);
  static const bold16 =
      AppTextStyleModel(fontSize: 16, fontWeight: FontWeight.w700);
  static const bold14 =
      AppTextStyleModel(fontSize: 14, fontWeight: FontWeight.w700);
  static const bold12 =
      AppTextStyleModel(fontSize: 12, fontWeight: FontWeight.w700);
  static const bold10 =
      AppTextStyleModel(fontSize: 10, fontWeight: FontWeight.w700);
}
