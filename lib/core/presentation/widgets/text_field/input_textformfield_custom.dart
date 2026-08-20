import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';

class InputTextFormFieldCustom extends StatefulWidget {
  final double height;
  final double? textSize;
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
  final TextCapitalization textCapitalization;
  final bool? showCursor;
  final Widget? leftWidget;
  final Widget? rightWidget;

  const InputTextFormFieldCustom({
    super.key,
    this.height = 44.0,
    this.textSize = 16.0,
    this.hintColor,
    this.hintText,
    required this.obscureText,
    this.backgroundColor,
    this.focusedWidth = 1.0,
    this.enableWidth = 1.0,
    this.controller,
    this.focusedColor = AppColors.t500,
    this.enableColor = AppColors.t500,
    this.onChanged,
    this.onCompleted,
    this.onTap,
    this.focusNode,
    this.labelText,
    this.textColor,
    this.keyboardType,
    this.isShowBorder = true,
    this.showCursor = true,
    this.textCapitalization = TextCapitalization.sentences,
    this.leftWidget,
    this.rightWidget,
    this.suffixIcon,
    this.prefixIcon,
  });

  @override
  State<InputTextFormFieldCustom> createState() =>
      _InputTextFormFieldCustomState();
}

class _InputTextFormFieldCustomState extends State<InputTextFormFieldCustom> {
  bool isError = false;

  // void _updateErrorState(bool hasError) {
  //   if (isError != hasError) {
  //     setState(() {
  //       isError = hasError;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.leftWidget != null) ...[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.leftWidget!,
                if (isError) const SizedBox(height: 22.0),
              ],
            ),
          ],
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 48.0,
                maxHeight: 230,
              ),
              child: TextFormField(
                key: widget.key,
                maxLength: 151,
                controller: widget.controller,
                focusNode: widget.focusNode,
                obscureText: widget.obscureText,
                textCapitalization: widget.textCapitalization,
                keyboardType: widget.keyboardType,
                showCursor: widget.showCursor,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                minLines: null,
                maxLines: null,
                onChanged: widget.onChanged,
                onFieldSubmitted: widget.onCompleted,
                validator: (value) {
                  // if (value != null) {
                  //   final words = value.trim().split(RegExp(r'\s+'));
                  //   print(words);
                  // }
                  String? errorMessage;

                  // if (value == null || value.trim().isEmpty) {
                  //   errorMessage =
                  //       "field_required".tr; // Thông báo khi trường bị bỏ trống
                  // } else if (value.length > 150) {
                  //   errorMessage = Utils.convertLanguage(
                  //       vi: 'Không được nhập quá 150 ký tự',
                  //       en: 'Do not enter more than 150 characters'); // Thông báo lỗi khi vượt quá 10 ký tự
                  // }

                  // final hasError = errorMessage != null;

                  // // Cập nhật trạng thái lỗi sau khi xây dựng widget
                  // WidgetsBinding.instance.addPostFrameCallback((_) {
                  //   _updateErrorState(hasError);
                  // });

                  return errorMessage;
                },
                style: TextStyle(
                  fontSize: widget.textSize,
                  color: widget.textColor ?? AppColors.black,
                  fontWeight: FontWeight.w400,
                  // fontFamily: AppFonts.beVietnamPro,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 10.0,
                  ),
                  labelText: widget.labelText,
                  counterText: '',
                  labelStyle: TextStyle(
                    // color: AppColors.brand,
                    fontSize: widget.textSize,
                  ),
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    fontSize: widget.textSize,
                    color: widget.hintColor,
                  ),
                  suffixIcon: widget.suffixIcon,
                  prefixIcon: widget.prefixIcon,
                  filled: widget.backgroundColor != null,
                  fillColor: widget.backgroundColor,
                  enabledBorder: widget.isShowBorder
                      ? OutlineInputBorder(
                          borderSide: BorderSide(
                            width: widget.enableWidth!,
                            color: widget.enableColor!,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
                        )
                      : null,
                  focusedBorder: widget.isShowBorder
                      ? OutlineInputBorder(
                          borderSide: BorderSide(
                            width: widget.focusedWidth!,
                            color: widget.focusedColor!,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
                        )
                      : null,
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: widget.enableWidth!,
                      color: widget.enableColor!,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: widget.enableWidth!,
                      color: widget.enableColor!,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
          ),
          if (widget.rightWidget != null) ...[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.rightWidget!,
                if (isError) const SizedBox(height: 22.0),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(text: newValue.text, selection: newValue.selection);
  }
}
