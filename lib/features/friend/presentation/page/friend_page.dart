import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keep_link/core/config/app_colors.dart';
import 'package:keep_link/core/extension/colors.dart';
import 'package:keep_link/core/ui/appbar/custom_app_bar.dart';
import 'package:keep_link/core/ui/image/cache_image.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';
import 'package:keep_link/core/ui/text_field/simple_input_textfield.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/friend/presentation/controller/friend_controller.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class FriendPage extends GetView<FriendController> {
  static const routeName = '/FriendPage';

  const FriendPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.bg700,
        appBar: CustomAppBar(title: 'Friends'.tr),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    _StatsRow(
                      totalFriends: controller.totalFriends,
                      remainingSlots: controller.remainingSlots,
                    ),
                    const SizedBox(height: 14),
                    _SearchBar(controller: controller),
                    const SizedBox(height: 12),
                    _ActionPanel(
                      controller: controller,
                      onPaste: () => _openAddByLinkSheet(context),
                      onScan: () => _openQrScanner(context),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilterChip(
                        selected: controller.favoritesOnly.value,
                        onSelected: (_) => controller.toggleFavoritesOnly(),
                        selectedColor: AppColors.primary.withOpacityCompat(0.2),
                        backgroundColor: AppColors.d500,
                        side: BorderSide(
                          color: controller.favoritesOnly.value
                              ? AppColors.primary
                              : AppColors.n500.withOpacityCompat(0.3),
                        ),
                        label: TextWidget(
                          text: 'Favorite Friends'.tr,
                          color: controller.favoritesOnly.value
                              ? AppColors.primary
                              : AppColors.white,
                          size: 13,
                        ),
                        avatar: Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: controller.favoritesOnly.value ? AppColors.primary : AppColors.n70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  if (controller.visibleFriends.isEmpty) {
                    return _EmptyState(
                      onPaste: () => _openAddByLinkSheet(context),
                      onScan: () => _openQrScanner(context),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemBuilder: (_, index) {
                      final friend = controller.visibleFriends[index];
                      return _FriendCard(
                        friend: friend,
                        onToggleFavorite: () => controller.toggleFavorite(friend),
                        onDelete: () => controller.confirmDeleteFriend(friend),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: controller.visibleFriends.length,
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _openAddByLinkSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.d500,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddFriendByLinkSheet(controller: controller),
    );
  }

  Future<void> _openQrScanner(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg700,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _QrScannerSheet(controller: controller),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.totalFriends, required this.remainingSlots});

  final int totalFriends;
  final int remainingSlots;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_alt_rounded,
            label: 'Total Friends'.tr,
            value: '$totalFriends/${FriendController.maxFriends}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.space_dashboard_rounded,
            label: 'Available Slots'.tr,
            value: '$remainingSlots',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.d500, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacityCompat(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: value,
                  color: AppColors.white,
                  size: 18,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 2),
                TextWidget(text: label, color: AppColors.n70, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final FriendController controller;

  @override
  Widget build(BuildContext context) {
    return SimpleInputTextField(
      controller: controller.searchController,
      hintText: 'Search friends'.tr,
      hintColor: AppColors.n70,
      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.n70),
      backgroundColor: AppColors.d500,
      textColor: AppColors.white,
      enableColor: AppColors.n500.withOpacityCompat(0.25),
      focusedColor: AppColors.primary,
      radius: 14,
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.controller, required this.onPaste, required this.onScan});

  final FriendController controller;
  final VoidCallback onPaste;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.d500,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.n500.withOpacityCompat(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: 'Add friends with personal link or QR'.tr,
            color: AppColors.white,
            size: 15,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 6),
          TextWidget(
            text: 'Each account can keep up to @0 friends.'.trParams({
              '0': '${FriendController.maxFriends}',
            }),
            color: AppColors.n70,
            size: 13,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.hasReachedLimit ? null : onPaste,
                  icon: const Icon(Icons.link_rounded, color: AppColors.white, size: 18),
                  label: TextWidget(text: 'Paste Link'.tr, color: AppColors.white, size: 13),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 46),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.hasReachedLimit ? null : onScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: TextWidget(text: 'Scan QR'.tr, color: AppColors.white, size: 13),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 46),
                    foregroundColor: AppColors.white,
                    side: BorderSide(color: AppColors.n500.withOpacityCompat(0.35)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend, required this.onToggleFavorite, required this.onDelete});

  final FriendModel friend;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.d500,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.n500.withOpacityCompat(0.18)),
      ),
      child: Row(
        children: [
          _FriendAvatar(friend: friend),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: friend.displayName,
                  color: AppColors.white,
                  size: 16,
                  fontWeight: FontWeight.w600,
                ),
                if ((friend.email ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: TextWidget(text: friend.email!, color: AppColors.n70, size: 12),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: TextWidget(
                    text: 'ID: ${friend.friendUserId}',
                    color: AppColors.n60,
                    size: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleFavorite,
            icon: Icon(
              friend.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: friend.isFavorite ? Colors.amber : AppColors.n70,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF7A7A)),
          ),
        ],
      ),
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({required this.friend});

  final FriendModel friend;

  @override
  Widget build(BuildContext context) {
    final photoUrl = friend.photoUrl ?? '';
    if (photoUrl.isNotEmpty) {
      return CacheImageWidget(
        imageUrl: photoUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(22),
        errorWidget: _FriendInitial(friend: friend),
      );
    }
    return _FriendInitial(friend: friend);
  }
}

class _FriendInitial extends StatelessWidget {
  const _FriendInitial({required this.friend});

  final FriendModel friend;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primary.withOpacityCompat(0.2),
      child: TextWidget(
        text: friend.displayName.isNotEmpty ? friend.displayName[0].toUpperCase() : '?',
        color: AppColors.primary,
        size: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPaste, required this.onScan});

  final VoidCallback onPaste;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 56,
              color: AppColors.n70.withOpacityCompat(0.7),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: 'No friends yet'.tr,
              color: AppColors.white,
              size: 18,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: 'Paste a personal link or scan a personal QR to add a friend.'.tr,
              color: AppColors.n70,
              size: 13,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPaste,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    icon: const Icon(Icons.link_rounded, color: AppColors.white),
                    label: TextWidget(text: 'Paste Link'.tr, color: AppColors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onScan,
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.white),
                    label: TextWidget(text: 'Scan QR'.tr, color: AppColors.white),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: BorderSide(color: AppColors.n500.withOpacityCompat(0.35)),
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

class _AddFriendByLinkSheet extends StatefulWidget {
  const _AddFriendByLinkSheet({required this.controller});

  final FriendController controller;

  @override
  State<_AddFriendByLinkSheet> createState() => _AddFriendByLinkSheetState();
}

class _AddFriendByLinkSheetState extends State<_AddFriendByLinkSheet> {
  late final TextEditingController _linkController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _linkController = TextEditingController();
    _loadClipboard();
  }

  Future<void> _loadClipboard() async {
    final clipboard = await widget.controller.readClipboardLink();
    if (!mounted || clipboard == null || clipboard.isEmpty) return;
    setState(() {
      _linkController.text = clipboard;
    });
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 18),
          TextWidget(
            text: 'Paste Friend Link'.tr,
            color: AppColors.white,
            size: 20,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 6),
          TextWidget(
            text: 'Paste the personal link your friend sent you.'.tr,
            color: AppColors.n70,
            size: 13,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _linkController,
            minLines: 3,
            maxLines: 5,
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              hintText: 'keeplink://open/friend?...',
              hintStyle: const TextStyle(color: AppColors.n70),
              filled: true,
              fillColor: AppColors.bg700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.n500.withOpacityCompat(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.n500.withOpacityCompat(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final clipboard = await widget.controller.readClipboardLink();
                    if (!mounted) return;
                    if (clipboard == null) {
                      messenger.showSnackBar(SnackBar(content: Text('friend_clipboard_empty'.tr)));
                      return;
                    }
                    setState(() {
                      _linkController.text = clipboard;
                    });
                  },
                  icon: const Icon(Icons.content_paste_rounded),
                  label: TextWidget(text: 'Paste from Clipboard'.tr, color: AppColors.white),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: BorderSide(color: AppColors.n500.withOpacityCompat(0.35)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          setState(() => _isSubmitting = true);
                          final success = await widget.controller.addFriendFromLink(
                            _linkController.text,
                          );
                          if (!mounted) return;
                          setState(() => _isSubmitting = false);
                          if (success) {
                            navigator.pop();
                          }
                        },
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : const Icon(Icons.person_add_alt_1_rounded, color: AppColors.white),
                  label: TextWidget(text: 'Add Friend'.tr, color: AppColors.white),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QrScannerSheet extends StatefulWidget {
  const _QrScannerSheet({required this.controller});

  final FriendController controller;

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {
  final MobileScannerController _scannerController = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isHandling = false;
  bool _isPickingImage = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickImageAndScan() async {
    if (_isHandling || _isPickingImage) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isPickingImage = true);
    var shouldResumeScanner = true;

    try {
      await _scannerController.stop();

      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }

      final capture = await _scannerController.analyzeImage(picked.path);
      final value = capture?.barcodes.firstOrNull?.rawValue?.trim();

      if (value == null || value.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text('friend_no_qr_found_in_image'.tr)));
        return;
      }

      _isHandling = true;
      final added = await widget.controller.addFriendFromLink(value);
      if (!mounted) return;
      if (added) {
        shouldResumeScanner = false;
        navigator.pop();
        return;
      }

      _isHandling = false;
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text('friend_scan_image_failed'.tr)));
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
      if (mounted && shouldResumeScanner) {
        await _scannerController.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.72,
      child: Column(
        children: [
          const SizedBox(height: 14),
          Container(
            width: 46,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.n500,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),
          TextWidget(
            text: 'Scan Personal QR'.tr,
            color: AppColors.white,
            size: 18,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          TextWidget(
            text: 'Point the camera at your friend\'s personal QR code.'.tr,
            color: AppColors.n70,
            size: 13,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) async {
                    final navigator = Navigator.of(context);
                    if (_isHandling) return;
                    final value = capture.barcodes.firstOrNull?.rawValue?.trim();
                    if (value == null || value.isEmpty) return;

                    _isHandling = true;
                    final added = await widget.controller.addFriendFromLink(value);
                    if (!mounted) return;
                    if (added) {
                      navigator.pop();
                      return;
                    }
                    _isHandling = false;
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isPickingImage
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            final data = await Clipboard.getData('text/plain');
                            final text = data?.text?.trim() ?? '';
                            if (text.isEmpty) {
                              _showMessage('friend_clipboard_empty'.tr);
                              return;
                            }
                            final added = await widget.controller.addFriendFromLink(text);
                            if (!mounted) return;
                            if (added) {
                              navigator.pop();
                            }
                          },
                    icon: const Icon(Icons.content_paste_rounded, color: AppColors.white),
                    label: TextWidget(text: 'Paste from Clipboard'.tr, color: AppColors.white),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: BorderSide(color: AppColors.n500.withOpacityCompat(0.35)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isPickingImage ? null : _pickImageAndScan,
                    icon: _isPickingImage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.photo_library_rounded, color: AppColors.white),
                    label: TextWidget(
                      text: _isPickingImage ? 'Scanning image...'.tr : 'Scan from Gallery'.tr,
                      color: AppColors.white,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: BorderSide(color: AppColors.n500.withOpacityCompat(0.35)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
