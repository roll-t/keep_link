import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_edge_insets.dart';
import 'package:keep_link/core/config/app_text_styles.dart';
import 'package:keep_link/core/config/app_vectors.dart';
import 'package:keep_link/core/ui/image/cache_image.dart';
import 'package:keep_link/core/ui/image/full_screen_image_page.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/link/application/controller/link_collection_controller.dart';
import 'package:keep_link/features/link/data/model/link_model.dart';
import 'package:keep_link/features/link/presentation/page/add_link_page.dart';

class LinkDetail extends StatelessWidget {
  final LinkModel link;
  const LinkDetail({super.key, required this.link});
  @override
  Widget build(BuildContext context) {
    final Size constraintSize = Size(Get.width * .98, Get.width * 1.5);
    return Center(
      child: Container(
        width: constraintSize.width,
        constraints: BoxConstraints(maxHeight: constraintSize.height),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppColors.d500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (link.metaDataModel?.imageUrl != "")
              GestureDetector(
                onTap: () {
                  final imageUrl = link.metaDataModel?.imageUrl ?? "";
                  if (imageUrl.isEmpty) return;
                  Get.to(() => FullScreenImagePage(imageUrl: imageUrl));
                },
                child: Hero(
                  tag: link.metaDataModel?.imageUrl ?? "",
                  child: CacheImageWidget(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    imageUrl: link.metaDataModel?.imageUrl ?? "/",
                    height: Get.width * .6,
                    width: constraintSize.width,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            Padding(
              padding: AppEdgeInsets.all12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (link.name?.isNotEmpty ?? false)
                        Expanded(
                          child: TextWidget(
                            text: (link.metaDataModel?.title ?? ""),
                            textStyle: AppTextStyle.semiBold20,
                            maxLines: 3,
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 12),
                  if (link.metaDataModel?.description.isNotEmpty ?? false)
                    TextWidget(
                      textAlign: TextAlign.start,
                      text: (link.metaDataModel?.description ?? ""),
                      maxLines: 5,
                    ),
                  GestureDetector(
                    onTap: () {
                      final textToCopy = link.metaDataModel?.url ?? "";
                      if (textToCopy.isEmpty) return;
                      Clipboard.setData(ClipboardData(text: textToCopy));
                      Fluttertoast.showToast(msg: "Đã sao chép");
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: SizedBox(
                        width: Get.width * .6,
                        child: Row(
                          spacing: 3,
                          children: [
                            AppVectors.icCopy.show(size: 15),
                            Expanded(
                              child: TextWidget(
                                text: (link.metaDataModel?.url ?? ""),
                                textStyle: AppTextStyle.regular12,
                                maxLines: 1,
                                textDecoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 24,
                    children: [
                      GetBuilder<LinkCollectionController>(
                        builder: (controller) {
                          return Expanded(
                            child: Row(
                              spacing: 16,
                              children: [
                                AppVectors.icEdit.show(
                                  backgroundColor: AppColors.d200,
                                  padding: EdgeInsets.all(8),
                                  onTap: () async {
                                    Get.back();
                                    Get.toNamed(AddLinkPage.routeName, arguments: link)?.then((
                                      success,
                                    ) {
                                      if (success is bool && success) {
                                        Get.find<LinkCollectionController>().onRefreshData();
                                      }
                                    });
                                  },
                                ),
                                AppVectors.icDelete.show(
                                  backgroundColor: AppColors.d200,
                                  padding: EdgeInsets.all(8),
                                  color: AppColors.red,
                                  onTap: () => controller.onDeleteLink(link.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          if (link.metaDataModel?.url.isNotEmpty ?? false) {
                            Utils.lanchUrl(link.metaDataModel?.url ?? "/");
                          }
                        },
                        child: Container(
                          height: 45,
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            spacing: 8,
                            children: [
                              const TextWidget(text: "Đi đến bài viết", color: AppColors.white),
                              Utils.getSocialIcon(urlSocial: link.metaDataModel?.url) ??
                                  const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
