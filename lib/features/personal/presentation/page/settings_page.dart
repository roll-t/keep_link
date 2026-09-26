import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/assets/app_vectors.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/localization/translation_service.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:keep_link/core/presentation/widgets/text/list_title_widget.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/services/platform/floating_link_bubble_service.dart';
import 'package:keep_link/features/personal/presentation/controller/personal_controller.dart';
import 'package:keep_link/features/personal/presentation/page/privacy_policy_page.dart';
import 'package:keep_link/features/personal/presentation/page/terms_page.dart';
import 'package:keep_link/features/security/presentation/page/security_method_page.dart';

class SettingsPage extends GetView<PersonalController> {
  static const routeName = '/SettingsPage';

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.bg700,
        appBar: CustomAppBar(
          title: "Settings".tr,
          centerTitle: false,
          titleStyle: AppTextStyle.bold20,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Preferences / General Settings ──────────────────────────
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    label: 'Language'.tr,
                    trailing: TextWidget(
                      text: LocalizationService.langs[Get.locale?.languageCode] ?? 'English',
                      color: AppColors.n70,
                      size: 13,
                    ),
                    onTap: () => _showLanguageBottomSheet(context),
                  ),
                  _SettingsTile(
                    icon: Icons.lock_rounded,
                    label: 'Security'.tr,
                    onTap: () =>
                        Get.toNamed(SecurityMethodPage.routeName, arguments: TypePage.create),
                  ),
                  Obx(
                    () => _SettingsTile(
                      leadingWidget: AppVectors.icAnonymous.show(
                        size: 20,
                        color: controller.isIncognitoWeb.value
                            ? AppColors.primary
                            : AppColors.n70,
                      ),
                      label: 'Open with Incognito'.tr,
                      trailing: Transform.scale(
                        scale: 0.72,
                        alignment: Alignment.centerRight,
                        child: Switch.adaptive(
                          value: controller.isIncognitoWeb.value,
                          activeTrackColor: AppColors.primary,
                          activeThumbColor: AppColors.primaryContainer,
                          inactiveThumbColor: AppColors.n400,
                          inactiveTrackColor: AppColors.white.withOpacityCompat(0.12),
                          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: controller.toggleIncognitoWeb,
                        ),
                      ),
                      onTap: () => controller.toggleIncognitoWeb(!controller.isIncognitoWeb.value),
                    ),
                  ),
                  // const _BubbleSettingTile(),
                ],
              ),

              // ── Support ───────────────────────────────────────────────────
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.star_rounded,
                    label: 'Rate App'.tr,
                    onTap: controller.rateApp,
                  ),
                  _SettingsTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Feedback & Bug Report'.tr,
                    onTap: controller.openFeedbackAndBugReport,
                  ),
                ],
              ),

              // ── About & Legal ─────────────────────────────────────────────
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.privacy_tip_rounded,
                    label: 'Privacy Policy'.tr,
                    onTap: () => Get.toNamed(PrivacyPolicyPage.routeName),
                  ),
                  _SettingsTile(
                    icon: Icons.description_rounded,
                    label: 'Terms of Service'.tr,
                    onTap: () => Get.toNamed(TermsPage.routeName),
                  ),
                  Obx(
                    () => _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: 'App Version'.tr,
                      trailing: TextWidget(
                        text: controller.appVersion.value.isNotEmpty
                            ? controller.appVersion.value
                            : '1.0.0',
                        color: AppColors.n70,
                        size: 13,
                      ),
                      onTap: null,
                    ),
                  ),
                ],
              ),

              // ── Login / Account Section (Screenshot 1) ───────────────────
              const SizedBox(height: 12),
              Obx(() {
                final currentUser = controller.user.value;
                final isLoggedIn = currentUser != null;

                return _SettingsCard(
                  children: [
                    if (isLoggedIn)
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        label: 'Đăng xuất'.tr,
                        trailing: const SizedBox.shrink(),
                        onTap: () => _showSignOutActionSheet(context),
                      )
                    else
                      _SettingsTile(
                        icon: Icons.login_rounded,
                        label: 'Đăng nhập'.tr,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.n400,
                          size: 20,
                        ),
                        onTap: controller.signInWithGoogle,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.d500,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prompt message (Screenshot 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              child: TextWidget(
                text: 'Bạn có chắc chắn muốn đăng xuất?'.tr,
                color: AppColors.n70,
                size: 13.5,
                fontWeight: FontWeight.w400,
                textAlign: TextAlign.center,
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: AppColors.white.withOpacityCompat(0.08)),
            // Option: Đăng xuất (Screenshot 2)
            InkWell(
              onTap: () {
                Navigator.of(sheetContext).pop();
                controller.confirmSignOut();
              },
              child: Container(
                height: 52,
                alignment: Alignment.center,
                child: TextWidget(
                  text: 'Đăng xuất'.tr,
                  color: AppColors.danger,
                  size: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(height: 8, color: AppColors.bg700),
            // Option: Hủy (Screenshot 2)
            InkWell(
              onTap: () => Navigator.of(sheetContext).pop(),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                child: TextWidget(
                  text: 'Hủy'.tr,
                  color: AppColors.white,
                  size: 15.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.d500,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: TextWidget(
                        text: 'Language'.tr,
                        color: AppColors.white,
                        size: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(Icons.close_rounded, color: AppColors.white, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...LocalizationService.langs.entries.map((entry) {
                final langCode = entry.key;
                final langName = entry.value;
                final isSelected = Get.locale?.languageCode == langCode;

                return InkWell(
                  onTap: () async {
                    await LocalizationService.changeLocale(langCode);
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextWidget(
                          text: langName,
                          color: AppColors.white,
                          size: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        if (isSelected)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.white,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white.withOpacityCompat(0.25),
                                width: 1.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

enum _BubbleSetupStep { idle, overlay, accessibility }

class _BubbleSettingTile extends StatefulWidget {
  const _BubbleSettingTile();

  @override
  State<_BubbleSettingTile> createState() => _BubbleSettingTileState();
}

class _BubbleSettingTileState extends State<_BubbleSettingTile> with WidgetsBindingObserver {
  bool _enabled = AppGetStorage.isFloatingLinkBubbleEnabled();
  bool _running = false;
  bool _busy = true;
  _BubbleSetupStep _setupStep = _BubbleSetupStep.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    Future<void>.delayed(const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      if (_setupStep == _BubbleSetupStep.idle) {
        await _refreshStatus();
      } else {
        await _resumePermissionFlow();
      }
    });
  }

  Future<void> _refreshStatus() async {
    try {
      var status = await FloatingLinkBubbleService.getStatus();
      if (_enabled && status.overlayGranted && status.accessibilityGranted && !status.running) {
        await FloatingLinkBubbleService.start();
        status = await FloatingLinkBubbleService.getStatus();
      }
      if (!mounted) return;
      setState(() {
        _running = status.running;
        _busy = false;
        if (_enabled && (!status.overlayGranted || !status.accessibilityGranted)) {
          _enabled = false;
          AppGetStorage.setFloatingLinkBubbleEnabled(false);
        }
      });
    } on PlatformException {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onChanged(bool value) async {
    if (_busy) return;
    setState(() {
      _enabled = value;
      _busy = true;
      _setupStep = _BubbleSetupStep.idle;
    });
    AppGetStorage.setFloatingLinkBubbleEnabled(value);

    if (!value) {
      await FloatingLinkBubbleService.stop();
      if (!mounted) return;
      setState(() {
        _running = false;
        _busy = false;
      });
      return;
    }

    await _beginPermissionFlow();
  }

  Future<void> _beginPermissionFlow() async {
    final status = await FloatingLinkBubbleService.getStatus();
    if (!mounted) return;
    if (!status.overlayGranted) {
      setState(() {
        _setupStep = _BubbleSetupStep.overlay;
        _busy = false;
      });
      await FloatingLinkBubbleService.requestOverlayPermission();
      return;
    }
    if (!status.accessibilityGranted) {
      setState(() {
        _setupStep = _BubbleSetupStep.accessibility;
        _busy = false;
      });
      await FloatingLinkBubbleService.requestAccessibilityPermission();
      return;
    }
    await _startBubble();
  }

  Future<void> _resumePermissionFlow() async {
    final status = await FloatingLinkBubbleService.getStatus();
    if (!mounted) return;

    if (_setupStep == _BubbleSetupStep.overlay) {
      if (!status.overlayGranted) {
        _cancelSetup('Cần quyền hiển thị trên ứng dụng khác để bật bóng');
        return;
      }
      if (!status.accessibilityGranted) {
        setState(() => _setupStep = _BubbleSetupStep.accessibility);
        await FloatingLinkBubbleService.requestAccessibilityPermission();
        return;
      }
    } else if (_setupStep == _BubbleSetupStep.accessibility && !status.accessibilityGranted) {
      _cancelSetup('Cần bật Trợ năng Linkeep để đọc URL hiện tại');
      return;
    }
    await _startBubble();
  }

  Future<void> _startBubble() async {
    final started = await FloatingLinkBubbleService.start();
    if (!mounted) return;
    setState(() {
      _running = started;
      _enabled = started;
      _busy = false;
      _setupStep = _BubbleSetupStep.idle;
    });
    AppGetStorage.setFloatingLinkBubbleEnabled(started);
    if (!started) _showMessage('Không thể khởi động bóng lưu nhanh');
  }

  void _cancelSetup(String message) {
    setState(() {
      _enabled = false;
      _running = false;
      _busy = false;
      _setupStep = _BubbleSetupStep.idle;
    });
    AppGetStorage.setFloatingLinkBubbleEnabled(false);
    _showMessage(message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _subtitle {
    if (_setupStep == _BubbleSetupStep.overlay) {
      return 'Cấp quyền hiển thị trên ứng dụng khác';
    }
    if (_setupStep == _BubbleSetupStep.accessibility) {
      return 'Bật Linkeep trong mục Trợ năng';
    }
    if (_running) return 'Chạm bóng để lưu trang web hoặc video TikTok';
    return 'Lưu nhanh link khi đang dùng ứng dụng khác';
  }

  @override
  Widget build(BuildContext context) {
    return ListTitleWidget(
      icon: Icons.bubble_chart_rounded,
      title: 'Bóng lưu nhanh',
      subtitle: _subtitle,
      trailing: _busy
          ? const SizedBox.square(
              dimension: 22,
              child: Padding(
                padding: EdgeInsets.all(3),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Transform.scale(
              scale: 0.72,
              child: Switch.adaptive(value: _enabled, onChanged: _onChanged),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.d500),
      child: Material(
        color: AppColors.transparent,
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 52,
                  endIndent: 0,
                  color: AppColors.white.withOpacityCompat(0.08),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    this.icon,
    this.leadingWidget,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData? icon;
  final Widget? leadingWidget;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: leadingWidget ??
            (icon != null ? Icon(icon, color: AppColors.n70, size: 21) : null),
        title: TextWidget(
          text: label,
          color: AppColors.white,
          size: 14,
          fontWeight: FontWeight.w500,
        ),
        trailing:
            trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right_rounded, color: AppColors.n400, size: 20)
                : null),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        minLeadingWidth: 24,
        dense: true,
      ),
    );
  }
}
