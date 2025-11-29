import 'package:flutter/material.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/features/link/presentation/widget/action_add_link.dart';
import 'package:keep_link/features/link/presentation/widget/header_link_collection.dart';
import 'package:keep_link/features/link/presentation/widget/list_link_collection.dart';

class LinkCollectionPage extends StatelessWidget {
  static const String routeName = "/LinkCollectionPage";

  const LinkCollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: const _BodyBuilder(), floatingActionButton: ActionAddLink());
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
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.black.withOpacityCompat(.9),
                AppColors.black.withOpacityCompat(.3),
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
