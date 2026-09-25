import 'package:flutter/material.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_theme.dart';
import 'package:keep_link/core/services/platform/deep_link_service.dart';
import 'package:keep_link/features/link/module/link_quick_save/presentation/page/quick_share_page.dart';

class QuickShareApp extends StatelessWidget {
  const QuickShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: AppColors.transparent,
      theme: AppTheme.dark,
      home: QuickSharePage(sharedText: DeepLinkService.sharedText ?? ''),
    );
  }
}
