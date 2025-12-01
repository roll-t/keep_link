import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/utils/utils.dart';

class SimpleInputTextField extends StatelessWidget {
  /// Chiều cao của TextField
  final double height;

  /// Màu hint text
  final Color? hintColor;

  /// Hint text
  final String? hintText;

  /// Ẩn text (dùng cho password)
  final bool obscureText;

  /// Màu nền
  final Color? backgroundColor;

  /// Màu border khi focus
  final Color? focusedColor;

  /// Độ dày border khi focus
  final double? focusedWidth;

  /// Màu border khi enable
  final Color? enableColor;

  /// Độ dày border khi enable
  final double? enableWidth;

  /// Widget icon bên phải
  final Widget? suffixIcon;

  /// Widget icon bên trái
  final Widget? prefixIcon;

  /// Callback khi thay đổi text
  final ValueChanged<String>? onChanged;

  /// Callback khi hoàn thành (ấn enter)
  final ValueChanged<String>? onCompleted;

  /// Màu text
  final Color? textColor;

  /// Callback khi tap
  final VoidCallback? onTap;

  /// FocusNode
  final FocusNode? focusNode;

  /// Label text
  final String? labelText;

  /// Controller
  final TextEditingController? controller;

  /// Loại bàn phím
  final TextInputType? keyboardType;

  /// Hiển thị border hay không
  final bool isShowBorder;

  /// Cho phép nhập hay không
  final bool enable;

  /// Giới hạn ký tự
  final int? maxLength;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Kiểu viết hoa
  final TextCapitalization textCapitalization;

  /// Hiển thị con trỏ
  final bool showCursor;

  /// Kích thước font
  final double fontSize;

  /// Chiều rộng
  final double width;

  /// Số dòng tối đa
  final int? maxLine;

  /// Căn chỉnh dọc
  final TextAlignVertical? textAlignVertical;

  /// Căn chỉnh ngang
  final TextAlign textAlign;

  /// Padding trái
  final double contentPaddingLeft;

  /// Padding dưới khi scroll
  final double scrollPaddingBottom;

  /// Font weight
  final FontWeight fontWeight;

  /// Custom content padding
  final EdgeInsetsGeometry? contentPadding;

  /// Custom label style
  final TextStyle? labelStyle = null;

  /// Custom hint style
  final TextStyle? hintStyle;

  /// Số dòng tối thiểu
  final int? minLines;
  final String? label;
  final String errorText;

  /// Action khi nhấn enter
  final TextInputAction? textInputAction;

  /// Scroll physics
  final ScrollPhysics? scrollPhysics;
  final ScrollController? scrollController;
  const SimpleInputTextField({
    super.key,
    this.height = 44.0,
    this.onChanged,
    this.suffixIcon,
    this.prefixIcon,
    this.obscureText = false,
    this.backgroundColor = AppColors.d300,
    this.focusedWidth = 1,
    this.enableWidth = 1,
    this.controller,
    this.hintText,
    this.hintColor,
    this.focusedColor = AppColors.n50,
    this.enableColor = AppColors.d300,
    this.onTap,
    this.focusNode,
    this.labelText,
    this.textColor = AppColors.t200,
    this.onCompleted,
    this.keyboardType,
    this.isShowBorder = true,
    this.enable = true,
    this.maxLength,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.showCursor = true,
    this.fontSize = 16.0,
    this.maxLine = 1,
    this.textAlignVertical = TextAlignVertical.center,
    this.width = double.infinity,
    this.textAlign = TextAlign.start,
    this.contentPaddingLeft = 15.0,
    this.scrollPaddingBottom = 70.0,
    this.fontWeight = FontWeight.w400,
    this.hintStyle,
    this.contentPadding,
    this.minLines,
    this.textInputAction,
    this.label,
    this.errorText = "",
    this.scrollPhysics,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6),
            child: TextWidget(text: label!, textStyle: AppTextStyle.bold16),
          ),
        Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: maxLine != null && maxLine! > 1,
            child: TextField(
              scrollController: scrollController,
              scrollPhysics: scrollPhysics,
              textInputAction: textInputAction,
              minLines: minLines,
              scrollPadding: EdgeInsets.only(bottom: scrollPaddingBottom),
              maxLines: maxLine,
              textAlign: textAlign,
              expands: maxLine == null && height > 0,
              showCursor: showCursor,
              textCapitalization: textCapitalization,
              maxLength: maxLength,
              keyboardType: keyboardType,
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onCompleted,
              inputFormatters: inputFormatters,
              obscureText: obscureText,
              focusNode: focusNode,
              onTap: onTap,
              onTapOutside: (f) {
                Utils.dimissKeyboard();
              },
              style: TextStyle(
                fontSize: fontSize,
                color: textColor ?? AppColors.n500,
                fontWeight: fontWeight,
              ),
              decoration: InputDecoration(
                enabled: enable,
                alignLabelWithHint: false,
                counterText: "",
                border: InputBorder.none,
                contentPadding:
                    contentPadding ??
                    EdgeInsets.only(
                      left: textAlign == TextAlign.start ? contentPaddingLeft : 7.0,
                      top: textAlignVertical == TextAlignVertical.top ? 15 : 0,
                      right: 7.0,
                    ),
                labelText: labelText,
                labelStyle: labelStyle ?? const TextStyle(color: AppColors.primary, fontSize: 16),
                suffixIcon: suffixIcon,
                prefixIcon: prefixIcon,
                hintText: hintText,
                hintStyle:
                    hintStyle ??
                    TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: hintColor ?? AppColors.t600,
                    ),
                enabledBorder: isShowBorder
                    ? OutlineInputBorder(
                        borderSide: BorderSide(width: enableWidth!, color: enableColor!),
                        borderRadius: BorderRadius.circular(8.0),
                      )
                    : OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                focusedBorder: isShowBorder
                    ? OutlineInputBorder(
                        borderSide: BorderSide(width: focusedWidth!, color: focusedColor!),
                        borderRadius: BorderRadius.circular(8.0),
                      )
                    : OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
              ),
            ),
          ),
        ),

        if (errorText.trim().isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextWidget(
              text: " $errorText",
              textStyle: AppTextStyle.regular12,
              color: AppColors.red,
            ),
          ),
        ],
      ],
    );
  }
}
