import 'package:flutter/material.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/core/ui/image/cache_image.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/features/link/data/model/link_model.dart';

class LinkItem extends StatelessWidget {
  final int index;
  final LinkModel item;

  const LinkItem({super.key, required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Positioned.fill(
            child: CacheImageWidget(
              borderRadius: BorderRadius.circular(12),
              imageUrl: item.metaDataModel?.imageUrl ?? "/",
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.white.withOpacityCompat(.8),
              ),
              child: TextWidget(
                text: item.name ?? "",
                textAlign: TextAlign.center,
                textStyle: AppTextStyle.semiBold14,
                color: AppColors.t700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
