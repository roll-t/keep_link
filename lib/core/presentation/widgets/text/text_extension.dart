import 'package:flutter/material.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';

extension StringTextWidgetExt on String {
  /// Base text extension to quickly create a [TextWidget]
  TextWidget toText({
    double? size,
    Color? color = AppColors.t200,
    FontWeight? fontWeight,
    int? maxLines = 1000,
    TextAlign? textAlign,
    FontStyle? fontStyle,
    TextDecoration? textDecoration,
    String? fontFamily,
    TextTransformType transform = TextTransformType.normal,
    AppTextStyleModel? textStyle,
    EdgeInsets padding = EdgeInsets.zero,
    double? height,
    double? letterSpacing,
    TextOverflow? overflow = TextOverflow.ellipsis,
  }) {
    return TextWidget(
      text: this,
      size: size,
      color: color,
      fontWeight: fontWeight,
      maxLines: maxLines,
      textAlign: textAlign,
      fontStyle: fontStyle,
      textDecoration: textDecoration,
      fontFamily: fontFamily,
      transform: transform,
      textStyle: textStyle,
      padding: padding,
      height: height,
      letterSpacing: letterSpacing,
      overflow: overflow,
    );
  }

  // ── Regular Styles ──────────────────────────────────────────────────────────
  TextWidget textRegular8({
    Color? color = AppColors.n70,
    int? maxLines,
    TextAlign? textAlign,
    double? height,
  }) => toText(
    textStyle: AppTextStyle.regular8,
    color: color,
    maxLines: maxLines,
    textAlign: textAlign,
    height: height,
  );

  TextWidget textRegular10({
    Color? color = AppColors.n70,
    int? maxLines,
    TextAlign? textAlign,
    double? height,
  }) => toText(
    textStyle: AppTextStyle.regular10,
    color: color,
    maxLines: maxLines,
    textAlign: textAlign,
    height: height,
  );

  TextWidget textRegular12({
    Color? color = AppColors.white,
    int? maxLines,
    TextAlign? textAlign,
    double? height,
  }) => toText(
    textStyle: AppTextStyle.regular12,
    color: color,
    maxLines: maxLines,
    textAlign: textAlign,
    height: height,
  );

  TextWidget textRegular14({
    Color? color = AppColors.white,
    int? maxLines,
    TextAlign? textAlign,
    double? height,
  }) => toText(
    textStyle: AppTextStyle.regular14,
    color: color,
    maxLines: maxLines,
    textAlign: textAlign,
    height: height,
  );

  // ── Medium Styles ───────────────────────────────────────────────────────────
  TextWidget textMedium8({
    Color? color = AppColors.n70,
    int? maxLines,
    TextAlign? textAlign,
  }) => toText(
    textStyle: AppTextStyle.medium8,
    color: color,
    maxLines: maxLines,
    textAlign: textAlign,
  );

  TextWidget textMedium10({
    Color? color = AppColors.n70,
    int? maxLines,
    TextAlign? textAlign,
  }) => toText(
    textStyle: AppTextStyle.medium10,
    color: color,
    maxLines: maxLines,
    textAlign: textAlign,
  );

  TextWidget textMedium12({
    Color? color = AppColors.white,
    int? maxLines,
    TextAlign? textAlign,
  }) => toText(
    textStyle: AppTextStyle.medium12,
    color: color,
    maxLines: maxLines,
    textAlign: textAlign,
  );

  TextWidget textMedium14({
    Color? color = AppColors.white,
    int? maxLines,
    TextAlign? textAlign,
  }) => toText(
    textStyle: AppTextStyle.medium14,
    color: color,
    maxLines: maxLines,
    textAlign: textAlign,
  );

  // ── SemiBold Styles ─────────────────────────────────────────────────────────
  TextWidget textSemiBold8({
    Color? color = AppColors.white,
    int? maxLines,
    TextAlign? textAlign,
  }) => toText(
    textStyle: AppTextStyle.semiBold8,
    color: color,
    maxLines: maxLines,
    textAlign: textAlign,
  );

  TextWidget textSemiBold10({
    Color? color = AppColors.white,
    int? maxLines,
    TextAlign? textAlign,
  }) => toText(
    textStyle: AppTextStyle.semiBold10,
    color: color,
    maxLines: maxLines,
    textAlign: textAlign,
  );

  TextWidget textSemiBold12({
    Color? color = AppColors.white,
    int? maxLines,
    TextAlign? textAlign,
  }) => toText(
    textStyle: AppTextStyle.semiBold12,
    color: color,
    maxLines: maxLines,
    textAlign: textAlign,
  );

  TextWidget textSemiBold14({
    Color? color = AppColors.white,
    int? maxLines,
    TextAlign? textAlign,
  }) => toText(
    textStyle: AppTextStyle.semiBold14,
    color: color,
    maxLines: maxLines,
    textAlign: textAlign,
  );

  // ── Bold Styles ─────────────────────────────────────────────────────────────
  TextWidget textBold12({
    Color? color = AppColors.white,
    int? maxLines,
    TextAlign? textAlign,
  }) => toText(
    textStyle: AppTextStyle.bold12,
    color: color,
    maxLines: maxLines,
    textAlign: textAlign,
  );

  TextWidget textBold14({
    Color? color = AppColors.white,
    int? maxLines,
    TextAlign? textAlign,
  }) => toText(
    textStyle: AppTextStyle.bold14,
    color: color,
    maxLines: maxLines,
    textAlign: textAlign,
  );

  TextWidget textBold16({
    Color? color = AppColors.white,
    int? maxLines,
    TextAlign? textAlign,
  }) => toText(
    textStyle: AppTextStyle.bold16,
    color: color,
    maxLines: maxLines,
    textAlign: textAlign,
  );
}
