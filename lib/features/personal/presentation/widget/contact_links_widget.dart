import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactLinksWidget extends StatelessWidget {
  const ContactLinksWidget({super.key});

  static const _email = 'phuoctruong727@gmail.com';
  static const _zalo = '0838629035';

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _email);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('unable_open_email'.tr)));
      }
    }
  }

  Future<void> _openZalo(BuildContext context) async {
    final uri = Uri.parse('https://zalo.me/$_zalo');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('unable_open_zalo'.tr)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ContactTile(icon: Icons.email_rounded, label: _email, onTap: () => _openEmail(context)),
        const SizedBox(height: 8),
        _ContactTile(
          icon: Icons.chat_rounded,
          label: 'Zalo: $_zalo',
          onTap: () => _openZalo(context),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacityCompat(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacityCompat(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: TextWidget(
                text: label,
                color: AppColors.primary,
                size: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 14),
          ],
        ),
      ),
    );
  }
}
