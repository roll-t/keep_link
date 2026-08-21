import 'package:flutter/material.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final double textSize;
  final Color color;
  final VoidCallback? onPressed;
  final bool isMaxParent;
  final Color backgroundColor;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    this.textSize = 14,
    required this.onPressed,
    this.isMaxParent = false,
    this.backgroundColor = AppColors.primary,
    this.color = AppColors.t200,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : TextWidget(text: text, fontWeight: FontWeight.bold, size: textSize, color: color),
    );

    return isMaxParent ? SizedBox(width: double.infinity, child: button) : button;
  }
}
