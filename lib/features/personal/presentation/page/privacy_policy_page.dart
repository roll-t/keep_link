import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/personal/presentation/widget/contact_links_widget.dart';

class PrivacyPolicyPage extends StatelessWidget {
  static const routeName = '/PrivacyPolicyPage';
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.bg700,
        appBar: CustomAppBar(title: 'Privacy Policy'.tr),
        body: const SingleChildScrollView(padding: EdgeInsets.all(20), child: _PolicyContent()),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(title: 'privacy.introduction.title'.tr, body: 'privacy.introduction.body'.tr),
        _Section(title: 'privacy.info_collect.title'.tr, body: 'privacy.info_collect.body'.tr),
        _Section(title: 'privacy.usage.title'.tr, body: 'privacy.usage.body'.tr),
        _Section(title: 'privacy.storage.title'.tr, body: 'privacy.storage.body'.tr),
        _Section(title: 'privacy.third_party.title'.tr, body: 'privacy.third_party.body'.tr),
        _Section(title: 'privacy.deletion.title'.tr, body: 'privacy.deletion.body'.tr),
        _ContactSection(title: 'privacy.contact.title'.tr),
        _Section(title: 'privacy.notice.title'.tr, body: 'privacy.notice.body'.tr),
        const _LastUpdated(date: '21/04/2026'),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: title,
            color: AppColors.onSurface,
            size: 15,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 6),
          TextWidget(text: body, color: AppColors.onSurfaceVariant, size: 14),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: title,
            color: AppColors.onSurface,
            size: 15,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 10),
          const ContactLinksWidget(),
        ],
      ),
    );
  }
}

class _LastUpdated extends StatelessWidget {
  const _LastUpdated({required this.date});
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      child: TextWidget(
        text: 'Last updated: @0'.trParams({'0': date}),
        color: AppColors.outlineVariant,
        size: 12,
      ),
    );
  }
}
