import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/personal/presentation/widget/contact_links_widget.dart';

class TermsPage extends StatelessWidget {
  static const routeName = '/TermsPage';
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.bg700,
        appBar: CustomAppBar(title: 'Terms of Service'.tr),
        body: const SingleChildScrollView(padding: EdgeInsets.all(20), child: _TermsContent()),
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(title: 'terms.acceptance.title'.tr, body: 'terms.acceptance.body'.tr),
        _Section(title: 'terms.use.title'.tr, body: 'terms.use.body'.tr),
        _Section(title: 'terms.content.title'.tr, body: 'terms.content.body'.tr),
        _Section(title: 'terms.account.title'.tr, body: 'terms.account.body'.tr),
        _Section(title: 'terms.disclaimer.title'.tr, body: 'terms.disclaimer.body'.tr),
        _Section(title: 'terms.liability.title'.tr, body: 'terms.liability.body'.tr),
        _Section(title: 'terms.changes.title'.tr, body: 'terms.changes.body'.tr),
        _ContactSection(title: 'terms.contact.title'.tr),
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
