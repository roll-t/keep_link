import 'package:flutter/material.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/widgets/bottom_bar.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/widgets/header_link_collection.dart';
import 'package:keep_link/features/link/module/link_colections/presentation/widgets/list_link_collection.dart';

class LinkCollectionPage extends StatelessWidget {
  static const String routeName = "/LinkCollectionPage";

  const LinkCollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const _BodyBuilder(),
      extendBody: true,
      floatingActionButton: GlassBottomBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _BodyBuilder extends StatelessWidget {
  const _BodyBuilder();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListLinkCollection(),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.black.withOpacityCompat(.8),
                AppColors.black.withOpacityCompat(.5),
                AppColors.black.withOpacityCompat(.2),
                AppColors.transparent,
                AppColors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        HeaderLinkCollection(),
      ],
    );
  }
}
