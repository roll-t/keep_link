import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/core/services/backend/friend_connection_service.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

enum QrTemplateType { chibiCute, darkCarbon, cleanLight, deepAurora }

class MyQrPage extends StatefulWidget {
  static const routeName = '/MyQrPage';

  final FriendController? controller;

  const MyQrPage({super.key, this.controller});

  @override
  State<MyQrPage> createState() => _MyQrPageState();
}

class _MyQrPageState extends State<MyQrPage> {
  final GlobalKey _qrCardKey = GlobalKey();

  QrTemplateType _selectedTemplate = QrTemplateType.chibiCute;
  bool _isExporting = false;

  Future<Uint8List?> _captureCardBytes() async {
    try {
      final boundary = _qrCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToGallery() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final bytes = await _captureCardBytes();
      if (bytes == null) {
        AppToast.showToast(
          'personal_qr_save_failed'.tr,
          Icons.error_outline_rounded,
          color: Colors.red,
        );
        return;
      }

      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'keeplink_qr_${DateTime.now().millisecondsSinceEpoch}',
      );

      final isSuccess = (result['isSuccess'] == true) || (result['filePath'] != null);
      if (isSuccess) {
        AppToast.showToast(
          'personal_qr_saved'.tr,
          Icons.download_done_rounded,
          color: Colors.green,
        );
      } else {
        AppToast.showToast(
          'personal_qr_save_failed'.tr,
          Icons.error_outline_rounded,
          color: Colors.red,
        );
      }
    } catch (_) {
      AppToast.showToast(
        'personal_qr_save_failed'.tr,
        Icons.error_outline_rounded,
        color: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareQrCard() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final bytes = await _captureCardBytes();
      if (bytes == null) {
        AppToast.showToast(
          'personal_qr_save_failed'.tr,
          Icons.error_outline_rounded,
          color: Colors.red,
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/keeplink_qr.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)], text: 'KeepLink Friend QR'.tr);
    } catch (_) {
      AppToast.showToast(
        'personal_qr_save_failed'.tr,
        Icons.error_outline_rounded,
        color: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _copyLink(String friendLink) {
    Clipboard.setData(ClipboardData(text: friendLink));
    AppToast.showToast('personal_link_copied'.tr, Icons.check_circle_rounded, color: Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.currentUser;
    final friendLink = user != null ? FriendConnectionService.buildLink(user) : null;
    final displayName = user?.displayName ?? 'KeepLink User';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg700,
      appBar: AppBar(
        backgroundColor: AppColors.d500,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextWidget(
          text: 'My QR Code'.tr,
          color: AppColors.white,
          size: 17,
          fontWeight: FontWeight.w700,
        ),
        actions: [
          if (friendLink != null) ...[
            IconButton(
              icon: const Icon(Icons.brush_rounded, color: AppColors.white, size: 22),
              tooltip: 'Choose Template'.tr,
              onPressed: () => _openCustomizeBottomSheet(context),
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded, color: AppColors.white, size: 22),
              tooltip: 'Share QR'.tr,
              onPressed: _shareQrCard,
            ),
          ],
        ],
      ),
      body: friendLink == null
          ? Center(
              child: TextWidget(
                text: 'Please sign in to view your QR code.'.tr,
                color: AppColors.n70,
                size: 14,
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: RepaintBoundary(
                            key: _qrCardKey,
                            child: _buildQrTemplateCard(
                              template: _selectedTemplate,
                              displayName: displayName,
                              email: email,
                              friendLink: friendLink,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Quick Action Buttons (Copy / Save / Style)
                    Row(
                      children: [
                        // Button 1: Sao chép link
                        Expanded(
                          child: _ActionPillButton(
                            icon: Icons.copy_rounded,
                            label: 'Copy Link'.tr,
                            color: AppColors.d500,
                            iconColor: AppColors.primary,
                            onTap: () => _copyLink(friendLink),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Button 2: Lưu ảnh về máy
                        Expanded(
                          child: _ActionPillButton(
                            icon: Icons.download_rounded,
                            label: 'Save Image'.tr,
                            color: AppColors.primary,
                            iconColor: Colors.white,
                            textColor: Colors.white,
                            onTap: _saveToGallery,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _openCustomizeBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.d500,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.n500,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextWidget(
                      text: 'Choose Template'.tr,
                      color: AppColors.white,
                      size: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 4),
                    TextWidget(
                      text: 'Select your favorite QR poster design.'.tr,
                      color: AppColors.n70,
                      size: 13,
                    ),

                    const SizedBox(height: 20),

                    // Template Options Grid
                    Row(
                      children: [
                        // Template 1: Chibi Cute
                        Expanded(
                          child: _TemplateThumbnailCard(
                            title: 'Chibi Cute'.tr,
                            subtitle: 'Linkeep Poster',
                            isSelected: _selectedTemplate == QrTemplateType.chibiCute,
                            previewWidget: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/images/qr_template_chibi.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            onTap: () {
                              setModalState(() => _selectedTemplate = QrTemplateType.chibiCute);
                              setState(() => _selectedTemplate = QrTemplateType.chibiCute);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Template 2: Dark Minimal
                        Expanded(
                          child: _TemplateThumbnailCard(
                            title: 'Dark Modern'.tr,
                            subtitle: 'Minimalist',
                            isSelected: _selectedTemplate == QrTemplateType.darkCarbon,
                            previewWidget: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B1C21),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24, width: 1),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.qr_code_2_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                            ),
                            onTap: () {
                              setModalState(() => _selectedTemplate = QrTemplateType.darkCarbon);
                              setState(() => _selectedTemplate = QrTemplateType.darkCarbon);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Template 3: Clean Light
                        Expanded(
                          child: _TemplateThumbnailCard(
                            title: 'Clean Light'.tr,
                            subtitle: 'Minimalist',
                            isSelected: _selectedTemplate == QrTemplateType.cleanLight,
                            previewWidget: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.qr_code_2_rounded,
                                  color: Color(0xFF0068FF),
                                  size: 28,
                                ),
                              ),
                            ),
                            onTap: () {
                              setModalState(() => _selectedTemplate = QrTemplateType.cleanLight);
                              setState(() => _selectedTemplate = QrTemplateType.cleanLight);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Template 4: Aurora
                        Expanded(
                          child: _TemplateThumbnailCard(
                            title: 'Aurora'.tr,
                            subtitle: 'Gradient Glow',
                            isSelected: _selectedTemplate == QrTemplateType.deepAurora,
                            previewWidget: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E2838), Color(0xFF141923)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.qr_code_2_rounded,
                                  color: Color(0xFF1DD1A1),
                                  size: 28,
                                ),
                              ),
                            ),
                            onTap: () {
                              setModalState(() => _selectedTemplate = QrTemplateType.deepAurora);
                              setState(() => _selectedTemplate = QrTemplateType.deepAurora);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQrTemplateCard({
    required QrTemplateType template,
    required String displayName,
    required String email,
    required String friendLink,
  }) {
    switch (template) {
      case QrTemplateType.chibiCute:
        return _ChibiTemplateCard(displayName: displayName, email: email, friendLink: friendLink);

      case QrTemplateType.darkCarbon:
        return _ModernCardTemplate(
          displayName: displayName,
          email: email,
          friendLink: friendLink,
          bgColor: const Color(0xFF1B1C21),
          primaryTextColor: Colors.white,
          secondaryTextColor: AppColors.n70,
          qrColor: const Color(0xFF0068FF),
          qrBoxBg: Colors.white,
        );

      case QrTemplateType.cleanLight:
        return _ModernCardTemplate(
          displayName: displayName,
          email: email,
          friendLink: friendLink,
          bgColor: Colors.white,
          primaryTextColor: const Color(0xFF1A1A1A),
          secondaryTextColor: const Color(0xFF757575),
          qrColor: const Color(0xFF0068FF),
          qrBoxBg: const Color(0xFFF4F5F8),
        );

      case QrTemplateType.deepAurora:
        return _ModernCardTemplate(
          displayName: displayName,
          email: email,
          friendLink: friendLink,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2838), Color(0xFF141923)],
          ),
          primaryTextColor: Colors.white,
          secondaryTextColor: AppColors.n70,
          qrColor: const Color(0xFF1DD1A1),
          qrBoxBg: Colors.white,
        );
    }
  }
}

// ── Template 1: Chibi Poster Template (Image 1) ──────────────────────────────

class _ChibiTemplateCard extends StatelessWidget {
  final String displayName;
  final String email;
  final String friendLink;
  static const double size = 330.0;

  const _ChibiTemplateCard({
    required this.displayName,
    required this.email,
    required this.friendLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityCompat(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 1. Illustrated Poster Background (Blank template with slots)
            Positioned.fill(
              child: Image.asset('assets/images/qr_template_chibi.jpg', fit: BoxFit.cover),
            ),

            // 2. Dynamic QR Code inside the middle white box with center logo
            Positioned(
              left: size * 0.292,
              top: size * 0.372,
              width: size * 0.345,
              height: size * 0.345,
              child: QrImageView(
                data: friendLink,
                version: QrVersions.auto,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0068FF)),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0068FF),
                ),
                embeddedImage: const AssetImage('assets/images/i_logo_app.png'),
                embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(20, 20)),
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
              ),
            ),

            // 3. User Name Slot (Top capsule slot)
            Positioned(
              left: size * 0.280,
              right: size * 0.225,
              top: size * 0.804,
              height: size * 0.058,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextWidget(
                  text: displayName,
                  color: const Color(0xFF1E272E),
                  size: 12.0,
                  fontWeight: FontWeight.w800,
                  maxLines: 1,
                ),
              ),
            ),

            // 4. User Email Slot (Bottom capsule slot)
            Positioned(
              left: size * 0.280,
              right: size * 0.220,
              top: size * 0.885,
              height: size * 0.058,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextWidget(
                  text: email.isNotEmpty ? email : 'keeplink.app',
                  color: const Color(0xFF57606F),
                  size: 10.5,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modern Minimal Card Template ─────────────────────────────────────────────

class _ModernCardTemplate extends StatelessWidget {
  final String displayName;
  final String email;
  final String friendLink;
  final Color? bgColor;
  final Gradient? gradient;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color qrColor;
  final Color qrBoxBg;

  const _ModernCardTemplate({
    required this.displayName,
    required this.email,
    required this.friendLink,
    this.bgColor,
    this.gradient,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.qrColor,
    required this.qrBoxBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: bgColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacityCompat(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacityCompat(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Avatar + Name
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [qrColor, qrColor.withOpacityCompat(0.7)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: qrColor.withOpacityCompat(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: TextWidget(
              text: displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              color: Colors.white,
              size: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextWidget(
            text: displayName,
            color: primaryTextColor,
            size: 17,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 3),
            TextWidget(
              text: email,
              color: secondaryTextColor,
              size: 12,
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 20),

          // 2. QR Code Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: qrBoxBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacityCompat(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: friendLink,
              version: QrVersions.auto,
              size: 200,
              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle, color: qrColor),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: qrColor,
              ),
              backgroundColor: Colors.transparent,
            ),
          ),

          const SizedBox(height: 18),

          // 3. Footer Branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2_rounded, color: qrColor, size: 16),
              const SizedBox(width: 6),
              TextWidget(
                text: 'Scan to connect on KeepLink'.tr,
                color: secondaryTextColor,
                size: 11,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Action Pill Button ───────────────────────────────────────────────────────

class _ActionPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionPillButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacityCompat(0.08), width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              TextWidget(text: label, color: textColor, size: 13, fontWeight: FontWeight.w600),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Template Thumbnail Card ──────────────────────────────────────────────────

class _TemplateThumbnailCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final Widget previewWidget;
  final VoidCallback onTap;

  const _TemplateThumbnailCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.previewWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary.withOpacityCompat(0.15) : AppColors.bg700,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white.withOpacityCompat(0.08),
              width: isSelected ? 2 : 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 72, width: double.infinity, child: previewWidget),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: title,
                          color: isSelected ? AppColors.primary : Colors.white,
                          size: 13,
                          fontWeight: FontWeight.w700,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        TextWidget(text: subtitle, color: AppColors.n70, size: 11, maxLines: 1),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
