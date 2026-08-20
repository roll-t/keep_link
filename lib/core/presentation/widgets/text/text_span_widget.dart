import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';

class TextSpanWidget extends StatelessWidget {
  final String text1;
  final String text2;
  final double size;
  final int maxLine;
  final double lineHeight;
  final FontWeight fontWeight1;
  final FontWeight fontWeight2;
  final Color textColor2;
  final Color textColor1;
  final FontStyle fontStyle1;
  final FontStyle fontStyle2;

  const TextSpanWidget({
    super.key,
    required this.text1,
    required this.text2,
    this.size = 14,
    this.maxLine = 999,
    this.lineHeight = 1.2,
    this.fontWeight2 = FontWeight.normal,
    this.fontWeight1 = FontWeight.normal,
    this.textColor2 = AppColors.t700,
    this.textColor1 = AppColors.t700,
    this.fontStyle1 = FontStyle.normal,
    this.fontStyle2 = FontStyle.normal,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: maxLine,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: size,
          overflow: TextOverflow.ellipsis,
          color: AppColors.t700,
        ),
        children: [
          TextSpan(
            text: text1.tr,
            style: TextStyle(
              fontSize: size,
              overflow: TextOverflow.ellipsis,
              fontWeight: fontWeight1,
              color: textColor1,
              height: lineHeight,
              fontStyle: fontStyle1,
              fontFamily: "Itim",
            ),
          ),
          const TextSpan(text: " "), // Adding space between the texts
          TextSpan(
            text: text2.tr,
            style: TextStyle(
              fontSize: size,
              overflow: TextOverflow.ellipsis,
              fontWeight: fontWeight2,
              height: lineHeight,
              color: textColor2,
              fontStyle: fontStyle2,
              fontFamily: "Itim",
            ),
          ),
        ],
      ),
    );
  }
}
