import 'package:flutter/material.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/config/app_vectors.dart';

class ActionAddLink extends StatelessWidget {
  const ActionAddLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 3.1415926535 / 2,
      child: AppVectors.icAddLink.show(
        backgroundColor: AppColors.d200,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
