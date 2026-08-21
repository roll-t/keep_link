import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/services/backend/firebase_service.dart';
import 'package:keep_link/core/services/backend/friend_connection_service.dart';
import 'package:keep_link/core/utils/app_toast.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:keep_link/features/friend/presentation/page/my_qr_page.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrScannerPage extends StatefulWidget {
  static const routeName = '/QrScannerPage';

  final FriendController controller;

  const QrScannerPage({super.key, required this.controller});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerCtrl = MobileScannerController();
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animCtrl;
  bool _handled = false;
  bool _isTorchOn = false;
  String? _lastInvalidRaw;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _scannerCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerCtrl.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {}
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim() ?? '';
      if (raw.isEmpty) continue;

      final payload = FriendConnectionService.parseLink(raw);
      if (payload == null) {
        if (raw != _lastInvalidRaw) {
          _lastInvalidRaw = raw;
          AppToast.showToast(
            'friend_invalid_link'.tr,
            Icons.error_outline_rounded,
            color: Colors.red,
          );
        }
        return;
      }

      _handled = true;
      if (!mounted) return;
      final confirmed = await showFriendRequestConfirmSheet(context, payload);
      if (!mounted) return;
      if (!confirmed) {
        _handled = false;
        return;
      }

      Get.back();
      await widget.controller.addFriendFromLink(raw);
      break;
    }
  }

  Future<void> _pickFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final barcodeCapture = await _scannerCtrl.analyzeImage(image.path);
    if (barcodeCapture != null && mounted) {
      await _handleBarcode(barcodeCapture);
    } else {
      AppToast.showToast(
        'No QR code found'.tr,
        Icons.error_outline_rounded,
        color: Colors.red,
      );
    }
  }

  void _openMyPersonalQr() {
    Get.to(() => MyQrPage(controller: widget.controller));
  }

  @override
  Widget build(BuildContext context) {
    const scanBoxSize = 260.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerCtrl,
              onDetect: _handleBarcode,
            ),
          ),

          // 2. Momo-style Scanner Overlay
          Positioned.fill(
            child: _QrScannerOverlay(
              scanBoxSize: scanBoxSize,
              animation: _animCtrl,
            ),
          ),

          // 3. Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Get.back(),
                    ),
                    TextWidget(
                      text: 'Scan QR'.tr,
                      color: Colors.white,
                      size: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    _CircleIconButton(
                      icon: _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _isTorchOn ? const Color(0xFFFFD32A) : Colors.white,
                      onTap: _toggleTorch,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Scan Instruction
          Positioned(
            left: 24,
            right: 24,
            top: MediaQuery.of(context).size.height * 0.5 + (scanBoxSize / 2) + 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacityCompat(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextWidget(
                  text: 'Align QR code within frame to scan.'.tr,
                  color: Colors.white.withOpacityCompat(0.85),
                  size: 13,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // 5. Bottom Action Buttons (Momo Style)
          Positioned(
            left: 20,
            right: 20,
            bottom: 34,
            child: SafeArea(
              child: Row(
                children: [
                  // Button 1: Thư viện ảnh
                  Expanded(
                    child: _BottomActionButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Pick from Gallery'.tr,
                      onTap: _pickFromGallery,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Button 2: Mã QR của tôi
                  Expanded(
                    child: _BottomActionButton(
                      icon: Icons.qr_code_2_rounded,
                      label: 'My QR Code'.tr,
                      onTap: _openMyPersonalQr,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overlay Painter ──────────────────────────────────────────────────────────

class _QrScannerOverlay extends StatelessWidget {
  final double scanBoxSize;
  final Animation<double> animation;

  const _QrScannerOverlay({
    required this.scanBoxSize,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final scanBoxRect = Rect.fromCenter(
          center: Offset(screenWidth / 2, screenHeight * 0.5),
          width: scanBoxSize,
          height: scanBoxSize,
        );

        return Stack(
          children: [
            // Dark surrounding overlay with transparent cutout
            CustomPaint(
              size: Size(screenWidth, screenHeight),
              painter: _ScannerHolePainter(scanBoxRect: scanBoxRect),
            ),

            // 4 Corner brackets (Momo style)
            CustomPaint(
              size: Size(screenWidth, screenHeight),
              painter: _CornerBracketsPainter(scanBoxRect: scanBoxRect),
            ),

            // Animated Laser Line
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final lineY = scanBoxRect.top + (scanBoxRect.height * animation.value);
                return Positioned(
                  left: scanBoxRect.left + 12,
                  right: screenWidth - scanBoxRect.right + 12,
                  top: lineY - 1,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacityCompat(0.0),
                          AppColors.primary,
                          Colors.white,
                          AppColors.primary,
                          AppColors.primary.withOpacityCompat(0.0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacityCompat(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ScannerHolePainter extends CustomPainter {
  final Rect scanBoxRect;

  _ScannerHolePainter({required this.scanBoxRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacityCompat(0.62);
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanBoxRect, const Radius.circular(16)));

    final overlayPath = Path.combine(PathOperation.difference, backgroundPath, holePath);
    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerHolePainter oldDelegate) =>
      oldDelegate.scanBoxRect != scanBoxRect;
}

class _CornerBracketsPainter extends CustomPainter {
  final Rect scanBoxRect;

  _CornerBracketsPainter({required this.scanBoxRect});

  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 28.0;
    const cornerRadius = 16.0;
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final left = scanBoxRect.left;
    final top = scanBoxRect.top;
    final right = scanBoxRect.right;
    final bottom = scanBoxRect.bottom;

    // Top-Left Corner
    final tlPath = Path()
      ..moveTo(left, top + cornerLength)
      ..lineTo(left, top + cornerRadius)
      ..quadraticBezierTo(left, top, left + cornerRadius, top)
      ..lineTo(left + cornerLength, top);
    canvas.drawPath(tlPath, strokePaint);

    // Top-Right Corner
    final trPath = Path()
      ..moveTo(right - cornerLength, top)
      ..lineTo(right - cornerRadius, top)
      ..quadraticBezierTo(right, top, right, top + cornerRadius)
      ..lineTo(right, top + cornerLength);
    canvas.drawPath(trPath, strokePaint);

    // Bottom-Left Corner
    final blPath = Path()
      ..moveTo(left, bottom - cornerLength)
      ..lineTo(left, bottom - cornerRadius)
      ..quadraticBezierTo(left, bottom, left + cornerRadius, bottom)
      ..lineTo(left + cornerLength, bottom);
    canvas.drawPath(blPath, strokePaint);

    // Bottom-Right Corner
    final brPath = Path()
      ..moveTo(right - cornerLength, bottom)
      ..lineTo(right - cornerRadius, bottom)
      ..quadraticBezierTo(right, bottom, right, bottom - cornerRadius)
      ..lineTo(right, bottom - cornerLength);
    canvas.drawPath(brPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) =>
      oldDelegate.scanBoxRect != scanBoxRect;
}

// ── Circle Icon Button ───────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withOpacityCompat(0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacityCompat(0.12), width: 1),
        ),
        child: Center(
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

// ── Bottom Action Button (Momo style) ────────────────────────────────────────

class _BottomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F24).withOpacityCompat(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacityCompat(0.12), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacityCompat(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: TextWidget(
                  text: label,
                  color: Colors.white,
                  size: 13,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Modal Helper Functions ───────────────────────────────────────────────────

Future<void> showMyPersonalQrModal(BuildContext context, FriendController controller) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.d500,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => MyPersonalQrSheet(controller: controller),
  );
}

class MyPersonalQrSheet extends StatelessWidget {
  const MyPersonalQrSheet({super.key, required this.controller});

  final FriendController controller;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.currentUser;
    final friendLink = user != null ? FriendConnectionService.buildLink(user) : null;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.n500,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: 'My QR Code'.tr,
              color: AppColors.white,
              size: 18,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 6),
            TextWidget(
              text: 'Let your friends scan this QR to connect.'.tr,
              color: AppColors.n70,
              size: 13,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (friendLink != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacityCompat(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: friendLink,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: friendLink));
                    AppToast.showToast(
                      'personal_link_copied'.tr,
                      Icons.check_circle_rounded,
                      color: Colors.green,
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: TextWidget(
                    text: 'Copy Personal Link'.tr,
                    color: Colors.white,
                    size: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: TextWidget(
                  text: 'Please sign in to view your QR code.'.tr,
                  color: AppColors.n70,
                  size: 14,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<bool> showFriendRequestConfirmSheet(
  BuildContext context,
  FriendConnectionPayload payload,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.d500,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => FriendRequestConfirmSheet(payload: payload),
  );
  return result ?? false;
}

class FriendRequestConfirmSheet extends StatelessWidget {
  const FriendRequestConfirmSheet({super.key, required this.payload});

  final FriendConnectionPayload payload;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.n500,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 18),
            TextWidget(
              text: 'Add Friend'.tr,
              color: AppColors.white,
              size: 18,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 18),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacityCompat(0.18),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: TextWidget(
                text: payload.displayName.isNotEmpty ? payload.displayName[0].toUpperCase() : '?',
                color: AppColors.primary,
                size: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextWidget(
              text: payload.displayName,
              color: AppColors.white,
              size: 16,
              fontWeight: FontWeight.w700,
            ),
            if (payload.email != null && payload.email!.isNotEmpty) ...[
              const SizedBox(height: 4),
              TextWidget(
                text: payload.email!,
                color: AppColors.n70,
                size: 13,
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.white.withOpacityCompat(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: TextWidget(
                        text: 'cancel'.tr,
                        color: AppColors.white,
                        size: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: TextWidget(
                        text: 'Send Request'.tr,
                        color: Colors.white,
                        size: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
