import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_enum.dart';
import 'package:keep_link/core/config/app_text_styles.dart';

class TextWidget extends StatelessWidget {
  final String text;
  final double? size;
  final Color? color;
  final int? maxLines;
  final TextAlign? textAlign;
  final FontWeight? fontWeight;
  final List<Shadow>? listShadow;
  final TextDecoration? textDecoration;
  final FontStyle? fontStyle;
  final String? fontFamily;
  final TextTransformType transform;
  final AppTextStyleModel? textStyle;
  final EdgeInsets padding;
  final bool? colorFixed;

  const TextWidget({
    super.key,
    this.textAlign,
    this.listShadow,
    this.maxLines = 1000,
    required this.text,
    this.color,
    this.colorFixed = false,
    this.size = 14,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
    this.textDecoration = TextDecoration.none,
    this.fontFamily,
    this.transform = TextTransformType.normal,
    this.textStyle,
    this.padding = EdgeInsets.zero,
  });

  String _applyTransform(String value) {
    switch (transform) {
      case TextTransformType.uppercase:
        return value.toUpperCase();
      case TextTransformType.lowercase:
        return value.toLowerCase();
      case TextTransformType.capitalize:
        if (value.isEmpty) return value;
        return value[0].toUpperCase() + value.substring(1).toLowerCase();
      case TextTransformType.capitalizeWords:
        return value
            .split(' ')
            .map(
              (word) => word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                  : '',
            )
            .join(' ');
      case TextTransformType.normal:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final transformedText = _applyTransform(text.tr);
    return Padding(
      padding: padding,
      child: Text(
        transformedText,
        maxLines: maxLines,
        textAlign: textAlign,
        style: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.t200,
          fontSize: textStyle?.fontSize ?? size,
          fontStyle: fontStyle,
          shadows: listShadow,
          fontWeight: textStyle?.fontWeight ?? fontWeight,
          decoration: textDecoration,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
