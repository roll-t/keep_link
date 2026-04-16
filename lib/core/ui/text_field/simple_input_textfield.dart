import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/utils/utils.dart';

class SimpleInputTextField extends StatefulWidget {
  final double height;
  final Color? hintColor;
  final String? hintText;
  final bool obscureText;
  final Color? backgroundColor;
  final Color? focusedColor;
  final double? focusedWidth;
  final Color? enableColor;
  final double? enableWidth;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final Color? textColor;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final String? labelText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool isShowBorder;
  final bool enable;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool showCursor;
  final double fontSize;
  final double width;
  final int? maxLine;
  final TextAlignVertical? textAlignVertical;
  final TextAlign textAlign;
  final double contentPaddingLeft;
  final double scrollPaddingBottom;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final int? minLines;
  final String? label;
  final String errorText;
  final TextInputAction? textInputAction;
  final double? radius;
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
    this.radius,
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
    this.labelStyle,
  });

  @override
  State<SimpleInputTextField> createState() => _SimpleInputTextFieldState();
}

class _SimpleInputTextFieldState extends State<SimpleInputTextField> {
  // Biến quản lý ScrollController nội bộ
  ScrollController? _localScrollController;

  @override
  void initState() {
    super.initState();
    // Nếu ở ngoài không truyền scrollController vào VÀ text field có nhiều dòng, ta tự khởi tạo một cái
    if (widget.scrollController == null && widget.maxLine != null && widget.maxLine! > 1) {
      _localScrollController = ScrollController();
    }
  }

  @override
  void dispose() {
    // Nhớ hủy nó để tránh rò rỉ bộ nhớ
    _localScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng controller được truyền từ ngoài vào, nếu không có thì dùng cái nội bộ
    final effectiveScrollController = widget.scrollController ?? _localScrollController;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6),
            child: TextWidget(text: widget.label!, textStyle: AppTextStyle.bold16),
          ),
        Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.radius ?? 8.0),
          ),
          child: Scrollbar(
            // CHỖ SỬA QUAN TRỌNG: Truyền controller dùng chung vào đây
            controller: effectiveScrollController,
            thumbVisibility: widget.maxLine != null && widget.maxLine! > 1,
            child: TextField(
              // CHỖ SỬA QUAN TRỌNG: Truyền controller dùng chung vào đây
              scrollController: effectiveScrollController,
              scrollPhysics: widget.scrollPhysics,
              textInputAction: widget.textInputAction,
              minLines: widget.minLines,
              scrollPadding: EdgeInsets.only(bottom: widget.scrollPaddingBottom),
              maxLines: widget.maxLine,
              textAlign: widget.textAlign,
              expands: widget.maxLine == null && widget.height > 0,
              showCursor: widget.showCursor,
              textCapitalization: widget.textCapitalization,
              maxLength: widget.maxLength,
              keyboardType: widget.keyboardType,
              controller: widget.controller,
              onChanged: widget.onChanged,
              onSubmitted: widget.onCompleted,
              inputFormatters: widget.inputFormatters,
              obscureText: widget.obscureText,
              focusNode: widget.focusNode,
              onTap: widget.onTap,
              onTapOutside: (f) {
                Utils.dimissKeyboard();
              },
              style: TextStyle(
                fontSize: widget.fontSize,
                color: widget.textColor ?? AppColors.n500,
                fontWeight: widget.fontWeight,
              ),
              decoration: InputDecoration(
                enabled: widget.enable,
                alignLabelWithHint: false,
                counterText: "",
                border: InputBorder.none,
                contentPadding:
                    widget.contentPadding ??
                    EdgeInsets.only(
                      left: widget.textAlign == TextAlign.start ? widget.contentPaddingLeft : 7.0,
                      top: widget.textAlignVertical == TextAlignVertical.top ? 15 : 0,
                      right: 7.0,
                    ),
                labelText: widget.labelText,
                labelStyle:
                    widget.labelStyle ?? const TextStyle(color: AppColors.primary, fontSize: 16),
                suffixIcon: widget.suffixIcon,
                prefixIcon: widget.prefixIcon,
                hintText: widget.hintText,
                hintStyle:
                    widget.hintStyle ??
                    TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: widget.hintColor ?? AppColors.t600,
                    ),
                enabledBorder: widget.isShowBorder
                    ? OutlineInputBorder(
                        borderSide: BorderSide(
                          width: widget.enableWidth!,
                          color: widget.enableColor!,
                        ),
                        borderRadius: BorderRadius.circular(widget.radius ?? 8.0),
                      )
                    : OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(widget.radius ?? 8.0),
                      ),
                focusedBorder: widget.isShowBorder
                    ? OutlineInputBorder(
                        borderSide: BorderSide(
                          width: widget.focusedWidth!,
                          color: widget.focusedColor!,
                        ),
                        borderRadius: BorderRadius.circular(widget.radius ?? 8.0),
                      )
                    : OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(widget.radius ?? 8.0),
                      ),
              ),
            ),
          ),
        ),
        if (widget.errorText.trim().isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextWidget(
              text: " ${widget.errorText}",
              textStyle: AppTextStyle.regular12,
              color: AppColors.red,
            ),
          ),
        ],
      ],
    );
  }
}
