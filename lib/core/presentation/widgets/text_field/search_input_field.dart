import 'package:flutter/material.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/utils/utils.dart';

/// Reusable compact search input field adhering to core design system.
class SearchInputField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final String? hintText;
  final double height;
  final double borderRadius;
  final Color backgroundColor;
  final FocusNode? focusNode;
  final bool autoFocus;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool showClearButton;
  final EdgeInsetsGeometry? contentPadding;
  final TextInputAction textInputAction;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  const SearchInputField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.hintText,
    this.height = 38.0,
    this.borderRadius = 20.0,
    this.backgroundColor = AppColors.d300,
    this.focusNode,
    this.autoFocus = false,
    this.prefixIcon,
    this.suffixIcon,
    this.showClearButton = true,
    this.contentPadding,
    this.textInputAction = TextInputAction.search,
    this.textStyle,
    this.hintStyle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSuffix =
        suffixIcon ??
        (showClearButton && controller != null && controller!.text.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  color: AppColors.n70,
                  size: 16,
                ),
                splashRadius: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  controller!.clear();
                  onChanged?.call('');
                  onClear?.call();
                },
              )
            : null);

    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autoFocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: textInputAction,
        textAlignVertical: TextAlignVertical.center,
        onTapOutside: (f) {
          Utils.dimissKeyboard();
        },
        style:
            textStyle ??
            const TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle:
              hintStyle ??
              const TextStyle(
                color: AppColors.n70,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
          prefixIcon:
              prefixIcon ??
              const Icon(Icons.search_rounded, color: AppColors.n70, size: 18),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: effectiveSuffix,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          filled: true,
          fillColor: backgroundColor,
          contentPadding:
              contentPadding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: AppColors.primary, width: 1),
          ),
        ),
      ),
    );
  }
}
