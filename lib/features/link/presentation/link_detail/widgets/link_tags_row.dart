import 'package:flutter/material.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';

/// Hiện tại tags đang hardcode — nên truyền từ LinkModel sau này
class LinkTagsRow extends StatelessWidget {
  const LinkTagsRow({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Tag("ENTERTAINMENT", const Color(0xFF007A8A)),
      const SizedBox(width: 8),
      _Tag("TIKTOK", const Color(0xFF333333)),
    ],
  );
}

class _Tag extends StatelessWidget {
  final String text;
  final Color bgColor;
  const _Tag(this.text, this.bgColor);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
    child: TextWidget(text: text, textStyle: AppTextStyle.bold12, color: AppColors.white),
  );
}
